import ts from 'typescript';

/** Read only authored const data. Never import/evaluate application code. */
export function readStaticConstants(source, names, fileName = 'data.ts') {
  const ast = ts.createSourceFile(fileName, source, ts.ScriptTarget.Latest, true, ts.ScriptKind.TS);
  if (ast.parseDiagnostics.length) throw new Error(`${fileName}: invalid TypeScript`);
  const declarations = new Map();
  for (const statement of ast.statements) {
    if (!ts.isVariableStatement(statement)) continue;
    if (!(statement.declarationList.flags & ts.NodeFlags.Const)) continue;
    for (const declaration of statement.declarationList.declarations) {
      if (!ts.isIdentifier(declaration.name)) continue;
      const name = declaration.name.text;
      if (declarations.has(name)) throw new Error(`${fileName}: duplicate const ${name}`);
      declarations.set(name, declaration.initializer);
    }
  }
  let budget = 100_000;
  function literal(node, depth = 0) {
    if (!node || depth > 64 || --budget < 0) throw new Error(`${fileName}: invalid or excessive data`);
    const next = value => literal(value, depth + 1);
    if (ts.isAsExpression(node) || ts.isSatisfiesExpression(node) || ts.isParenthesizedExpression(node)) return next(node.expression);
    if (ts.isStringLiteral(node) || ts.isNoSubstitutionTemplateLiteral(node)) return node.text;
    if (ts.isNumericLiteral(node)) {
      const n = Number(node.text); if (!Number.isFinite(n)) throw new Error('Non-finite number'); return n;
    }
    if (node.kind === ts.SyntaxKind.TrueKeyword) return true;
    if (node.kind === ts.SyntaxKind.FalseKeyword) return false;
    if (node.kind === ts.SyntaxKind.NullKeyword) return null;
    if (ts.isPrefixUnaryExpression(node) && [ts.SyntaxKind.MinusToken, ts.SyntaxKind.PlusToken].includes(node.operator)) {
      const n = next(node.operand); if (typeof n !== 'number') throw new Error('Non-numeric unary operand');
      return node.operator === ts.SyntaxKind.MinusToken ? -n : n;
    }
    if (ts.isArrayLiteralExpression(node)) return node.elements.map(next);
    if (ts.isObjectLiteralExpression(node)) {
      const out = Object.create(null);
      for (const property of node.properties) {
        if (!ts.isPropertyAssignment(property) || !(ts.isIdentifier(property.name) || ts.isStringLiteral(property.name))) throw new Error('Only literal property assignments are supported');
        const key = property.name.text;
        if (['__proto__', 'constructor', 'prototype'].includes(key) || Object.hasOwn(out, key)) throw new Error(`Unsafe/duplicate key: ${key}`);
        out[key] = next(property.initializer);
      }
      return out;
    }
    if (ts.isCallExpression(node) && ts.isPropertyAccessExpression(node.expression)
      && ts.isIdentifier(node.expression.expression) && node.expression.expression.text === 'Object'
      && node.expression.name.text === 'freeze' && node.arguments.length === 1) return next(node.arguments[0]);
    throw new Error(`${fileName}: unsupported static syntax ${ts.SyntaxKind[node.kind]}; move data to a shared JSON/Resource before exporting`);
  }
  const result = Object.create(null);
  for (const name of names) {
    if (!declarations.has(name)) throw new Error(`${fileName}: missing const ${name}`);
    result[name] = literal(declarations.get(name));
  }
  return result;
}

export function validateSpatialManifest(data) {
  const finite = value => typeof value === 'number' && Number.isFinite(value);
  const positive = value => finite(value) && value > 0;
  if (data.schemaVersion !== 1 || !positive(data.world?.width) || !positive(data.world?.height)
    || data.world.width > 32768 || data.world.height > 32768) throw new Error('Invalid world/schema');
  if (!positive(data.viewport?.width) || !positive(data.viewport?.height)) throw new Error('Invalid viewport');
  for (const key of ['collisions', 'occlusion']) {
    if (!Array.isArray(data[key]) || data[key].length > 10000) throw new Error(`Invalid ${key}`);
    const ids = new Set();
    for (const r of data[key]) {
      if (typeof r.id !== 'string' || !r.id || ids.has(r.id)) throw new Error(`Duplicate/invalid ${key} id`);
      ids.add(r.id);
      if (![r.left, r.top, r.right, r.bottom].every(finite) || r.left < 0 || r.top < 0
        || r.right <= r.left || r.bottom <= r.top || r.right > data.world.width || r.bottom > data.world.height) throw new Error(`Invalid bounds: ${r.id}`);
      if (key === 'occlusion' && (!finite(r.sortY) || r.sortY < 0 || r.sortY > data.world.height)) throw new Error(`Invalid sortY: ${r.id}`);
    }
  }
  for (const zone of ['lobby', 'auditorium', 'stage']) {
    const s = data.spawns?.[zone];
    if (!s || !finite(s.x) || !finite(s.y) || s.x < 0 || s.y < 0 || s.x > data.world.width || s.y > data.world.height) throw new Error(`Invalid spawn: ${zone}`);
  }
  const p = data.player, f = p?.foot;
  if (!p || ![p.width, p.height, p.scale, p.frameMs, p.frameCount].every(positive)
    || !Number.isInteger(p.frameCount) || p.frameCount > 64 || p.scale > 8 || !f
    || !positive(f.width) || !positive(f.height) || !finite(f.offsetX) || !finite(f.offsetY)
    || f.offsetX < 0 || f.offsetY < 0 || f.offsetX + f.width > p.width || f.offsetY + f.height > p.height) throw new Error('Invalid player contract');
  return data;
}
