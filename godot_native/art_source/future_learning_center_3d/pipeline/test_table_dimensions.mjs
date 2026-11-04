import fs from 'node:fs/promises';
import {validateTableDimensions} from './table_dimension_contract.mjs';
const result=await validateTableDimensions();
await fs.writeFile('review/table_dimension_validation.json',JSON.stringify(result,null,2)+'\n');
console.log(`Table dimensions: ${result.checks} checks passed`);
