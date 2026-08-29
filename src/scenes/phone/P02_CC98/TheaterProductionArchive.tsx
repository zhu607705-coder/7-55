import { useState } from "react";
import posterUrl from "../../../assets/ui/cc98/theater_755_student_play_poster_v01.png";
import theaterContent from "../../../data/chapter3-theater.content.json";

const copy = theaterContent.cc98TicketCommission.productionArchive;

/** 帖内演出资料只补充世界观，不参与票务与章节进度判定。 */
export function TheaterProductionArchive() {
  const [expanded, setExpanded] = useState(false);

  return (
    <section className={`cc98-theater-archive ${expanded ? "is-expanded" : ""}`} aria-label="学生剧《7:55》演出档案">
      <header className="cc98-theater-archive-heading">
        <span>演出档案</span>
        <strong>原创学生剧</strong>
      </header>

      <div className="cc98-theater-poster-card">
        <figure>
          <img src={posterUrl} alt={copy.posterAlt} />
        </figure>
        <div className="cc98-theater-poster-copy">
          <small>{copy.seasonLabel}</small>
          <h3>{copy.title}</h3>
          <p>{copy.tagline}</p>
          <dl>
            {copy.facts.slice(0, 3).map((fact) => (
              <div key={fact.label}>
                <dt>{fact.label}</dt>
                <dd>{fact.value}</dd>
              </div>
            ))}
          </dl>
        </div>
      </div>

      <button
        type="button"
        className="cc98-theater-archive-toggle"
        aria-expanded={expanded}
        onClick={() => setExpanded((current) => !current)}
      >
        <span>{expanded ? copy.collapseLabel : copy.expandLabel}</span>
        <i aria-hidden="true">{expanded ? "−" : "+"}</i>
      </button>

      {expanded ? (
        <div className="cc98-theater-archive-details">
          <section>
            <h4>剧情简介</h4>
            <p>{copy.summary}</p>
          </section>

          <section>
            <h4>演出信息</h4>
            <dl className="cc98-theater-fact-grid">
              {copy.facts.map((fact) => (
                <div key={fact.label}>
                  <dt>{fact.label}</dt>
                  <dd>{fact.value}</dd>
                </div>
              ))}
            </dl>
          </section>

          <section>
            <h4>制作分工</h4>
            <dl className="cc98-theater-credit-list">
              {copy.credits.map((credit) => (
                <div key={credit.role}>
                  <dt>{credit.role}</dt>
                  <dd>{credit.name}</dd>
                </div>
              ))}
            </dl>
          </section>

          <section>
            <h4>现场须知</h4>
            <ul>
              {copy.notices.map((notice) => <li key={notice}>{notice}</li>)}
            </ul>
          </section>
        </div>
      ) : null}
    </section>
  );
}
