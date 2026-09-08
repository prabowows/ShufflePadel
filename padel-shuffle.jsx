import React, { useState, useMemo } from "react";
import {
  Home,
  Trophy,
  Users,
  Plus,
  X,
  Shuffle,
  ChevronRight,
  ChevronLeft,
  UserPlus,
  Check,
  Clock,
  Minus,
  Trash2,
  Calendar,
} from "lucide-react";

// ---------- helpers ----------
const pairKey = (a, b) => [a, b].sort().join("|");

const emptyPlayer = (name) => ({
  id: `p${Date.now()}-${Math.round(Math.random() * 100000)}`,
  name,
  played: 0,
  wins: 0,
  losses: 0,
  scoreFor: 0,
  scoreAgainst: 0,
  status: "ready", // ready | playing
  checkedIn: true,
  history: [], // {matchNumber, court, partner, opponents:[], score, result}
});

const defaultSession = () => ({
  name: "",
  date: "",
  timeStart: "",
  timeEnd: "",
  courtsTotal: 2,
});

export default function App() {
  const [setupStep, setSetupStep] = useState("create"); // create | roster | app
  const [session, setSession] = useState(defaultSession);
  const [rosterDraft, setRosterDraft] = useState("");
  const [rosterPlayers, setRosterPlayers] = useState([]); // built during setup

  const [players, setPlayers] = useState([]);
  const [matches, setMatches] = useState([]); // all matches, active + finished
  const [pairHistory, setPairHistory] = useState({}); // key -> {partner, opponent}
  const [matchCounter, setMatchCounter] = useState(1);

  const COURTS_TOTAL = session.courtsTotal;

  const [activeTab, setActiveTab] = useState("home");
  const [shuffleOpen, setShuffleOpen] = useState(false);
  const [shuffleError, setShuffleError] = useState("");
  const [scoreDrafts, setScoreDrafts] = useState({}); // matchId -> {a,b}
  const [selectedPlayerId, setSelectedPlayerId] = useState(null);
  const [newPlayerName, setNewPlayerName] = useState("");
  const [rankFilter, setRankFilter] = useState("points");

  const byId = useMemo(() => {
    const m = {};
    players.forEach((p) => (m[p.id] = p));
    return m;
  }, [players]);

  const activeMatches = matches
    .filter((m) => m.status === "playing")
    .sort((a, b) => a.court - b.court);
  const finishedMatches = matches
    .filter((m) => m.status === "finished")
    .sort((a, b) => b.matchNumber - a.matchNumber);

  const eligiblePlayers = players.filter(
    (p) => p.checkedIn && p.status === "ready"
  );
  const waitingPlayers = eligiblePlayers.slice().sort((a, b) => a.played - b.played);
  const notCheckedIn = players.filter((p) => !p.checkedIn);

  const occupiedCourts = activeMatches.map((m) => m.court);
  const freeCourts = COURTS_TOTAL - occupiedCourts.length;

  // ---------- pair history helpers ----------
  const getCount = (id1, id2, type) => {
    const k = pairKey(id1, id2);
    return pairHistory[k]?.[type] || 0;
  };

  // ---------- shuffle algorithm ----------
  function tryShuffle(numMatches) {
    const needed = numMatches * 4;
    if (eligiblePlayers.length < needed) {
      setShuffleError(`Belum cukup pemain untuk ${numMatches} match. Butuh ${needed}, tersedia ${eligiblePlayers.length}.`);
      return;
    }
    if (freeCourts < numMatches) {
      setShuffleError(`Court tidak cukup. Tersisa ${freeCourts} court kosong.`);
      return;
    }
    setShuffleError("");

    // priority: fewest matches played first, random tiebreak
    const pool = [...eligiblePlayers]
      .sort((a, b) => a.played - b.played || Math.random() - 0.5)
      .slice(0, needed);

    // search for a low-penalty grouping into foursomes + team splits
    let best = null;
    let bestScore = Infinity;
    for (let attempt = 0; attempt < 250; attempt++) {
      const shuffled = [...pool].sort(() => Math.random() - 0.5);
      const groups = [];
      for (let i = 0; i < shuffled.length; i += 4) groups.push(shuffled.slice(i, i + 4));

      let score = 0;
      const assignment = groups.map((g) => {
        const [p1, p2, p3, p4] = g;
        const splits = [
          { teamA: [p1, p2], teamB: [p3, p4] },
          { teamA: [p1, p3], teamB: [p2, p4] },
          { teamA: [p1, p4], teamB: [p2, p3] },
        ];
        let bestSplit = null;
        let bestSplitScore = Infinity;
        splits.forEach((s) => {
          const partnerPenalty =
            getCount(s.teamA[0].id, s.teamA[1].id, "partner") * 3 +
            getCount(s.teamB[0].id, s.teamB[1].id, "partner") * 3;
          let oppPenalty = 0;
          s.teamA.forEach((a) =>
            s.teamB.forEach((b) => (oppPenalty += getCount(a.id, b.id, "opponent")))
          );
          const total = partnerPenalty + oppPenalty;
          if (total < bestSplitScore) {
            bestSplitScore = total;
            bestSplit = s;
          }
        });
        score += bestSplitScore;
        return bestSplit;
      });

      if (score < bestScore) {
        bestScore = score;
        best = assignment;
      }
      if (bestScore === 0) break;
    }

    // assign to free courts
    const availableCourts = [];
    for (let c = 1; c <= COURTS_TOTAL; c++) if (!occupiedCourts.includes(c)) availableCourts.push(c);

    const newMatches = best.map((g, idx) => ({
      id: `m${matchCounter + idx}`,
      matchNumber: matchCounter + idx,
      court: availableCourts[idx],
      teamA: g.teamA.map((p) => p.id),
      teamB: g.teamB.map((p) => p.id),
      scoreA: null,
      scoreB: null,
      status: "playing",
    }));

    // update pair history
    const nextPairHistory = { ...pairHistory };
    newMatches.forEach((m) => {
      const [a1, a2] = m.teamA;
      const [b1, b2] = m.teamB;
      const bump = (k1, k2, type) => {
        const k = pairKey(k1, k2);
        nextPairHistory[k] = { ...nextPairHistory[k], [type]: (nextPairHistory[k]?.[type] || 0) + 1 };
      };
      bump(a1, a2, "partner");
      bump(b1, b2, "partner");
      [a1, a2].forEach((a) => [b1, b2].forEach((b) => bump(a, b, "opponent")));
    });
    setPairHistory(nextPairHistory);

    // mark players as playing
    const playingIds = new Set(newMatches.flatMap((m) => [...m.teamA, ...m.teamB]));
    setPlayers((prev) => prev.map((p) => (playingIds.has(p.id) ? { ...p, status: "playing" } : p)));

    setMatches((prev) => [...prev, ...newMatches]);
    setMatchCounter((c) => c + newMatches.length);
    setShuffleOpen(false);
  }

  // ---------- score submission ----------
  function submitScore(matchId) {
    const draft = scoreDrafts[matchId];
    if (!draft || draft.a === "" || draft.b === "") return;
    const a = Number(draft.a);
    const b = Number(draft.b);
    if (Number.isNaN(a) || Number.isNaN(b)) return;

    const match = matches.find((m) => m.id === matchId);
    const aWins = a > b;

    setMatches((prev) =>
      prev.map((m) => (m.id === matchId ? { ...m, scoreA: a, scoreB: b, status: "finished" } : m))
    );

    setPlayers((prev) =>
      prev.map((p) => {
        if (match.teamA.includes(p.id)) {
          const partner = byId[match.teamA.find((id) => id !== p.id)];
          const opponents = match.teamB.map((id) => byId[id].name);
          return {
            ...p,
            status: "ready",
            played: p.played + 1,
            wins: p.wins + (aWins ? 1 : 0),
            losses: p.losses + (aWins ? 0 : 1),
            scoreFor: p.scoreFor + a,
            scoreAgainst: p.scoreAgainst + b,
            history: [
              ...p.history,
              {
                matchNumber: match.matchNumber,
                court: match.court,
                partner: partner?.name,
                opponents,
                score: `${a}\u2013${b}`,
                result: aWins ? "W" : "L",
              },
            ],
          };
        }
        if (match.teamB.includes(p.id)) {
          const partner = byId[match.teamB.find((id) => id !== p.id)];
          const opponents = match.teamA.map((id) => byId[id].name);
          return {
            ...p,
            status: "ready",
            played: p.played + 1,
            wins: p.wins + (aWins ? 0 : 1),
            losses: p.losses + (aWins ? 1 : 0),
            scoreFor: p.scoreFor + b,
            scoreAgainst: p.scoreAgainst + a,
            history: [
              ...p.history,
              {
                matchNumber: match.matchNumber,
                court: match.court,
                partner: partner?.name,
                opponents,
                score: `${b}\u2013${a}`,
                result: aWins ? "L" : "W",
              },
            ],
          };
        }
        return p;
      })
    );

    setScoreDrafts((prev) => {
      const next = { ...prev };
      delete next[matchId];
      return next;
    });
  }

  // ---------- player management ----------
  function toggleCheckIn(id) {
    setPlayers((prev) =>
      prev.map((p) => (p.id === id && p.status !== "playing" ? { ...p, checkedIn: !p.checkedIn } : p))
    );
  }

  function addPlayer() {
    const name = newPlayerName.trim();
    if (!name) return;
    setPlayers((prev) => [
      ...prev,
      {
        id: `p${Date.now()}`,
        name,
        played: 0,
        wins: 0,
        losses: 0,
        scoreFor: 0,
        scoreAgainst: 0,
        status: "ready",
        checkedIn: true,
        history: [],
      },
    ]);
    setNewPlayerName("");
  }

  // ---------- ranking ----------
  const ranked = useMemo(() => {
    const withPts = players.map((p) => ({
      ...p,
      points: p.wins * 3 + (p.scoreFor - p.scoreAgainst),
      winRate: p.played > 0 ? Math.round((p.wins / p.played) * 100) : 0,
    }));
    const key = rankFilter === "points" ? "points" : rankFilter === "wins" ? "wins" : "winRate";
    return withPts.sort((a, b) => b[key] - a[key] || b.played - a.played);
  }, [players, rankFilter]);

  const checkedInCount = players.filter((p) => p.checkedIn).length;
  const totalFinished = finishedMatches.length;

  const selectedPlayer = selectedPlayerId ? byId[selectedPlayerId] : null;
  const selectedRank = selectedPlayer ? ranked.findIndex((p) => p.id === selectedPlayer.id) + 1 : null;

  function startTournament() {
    setSession((s) => ({ ...s, name: s.name.trim() || "Padel Session" }));
    setSetupStep("roster");
  }

  function addRosterPlayer() {
    const name = rosterDraft.trim();
    if (!name) return;
    setRosterPlayers((prev) => [...prev, emptyPlayer(name)]);
    setRosterDraft("");
  }

  function removeRosterPlayer(id) {
    setRosterPlayers((prev) => prev.filter((p) => p.id !== id));
  }

  function beginSession() {
    setPlayers(rosterPlayers);
    setSetupStep("app");
  }

  if (setupStep === "create") {
    return (
      <div style={styles.shell}>
        <style>{css}</style>
        <CreateTournamentScreen session={session} setSession={setSession} onNext={startTournament} />
      </div>
    );
  }

  if (setupStep === "roster") {
    return (
      <div style={styles.shell}>
        <style>{css}</style>
        <AddPlayersScreen
          session={session}
          rosterDraft={rosterDraft}
          setRosterDraft={setRosterDraft}
          rosterPlayers={rosterPlayers}
          addRosterPlayer={addRosterPlayer}
          removeRosterPlayer={removeRosterPlayer}
          onBack={() => setSetupStep("create")}
          onStart={beginSession}
        />
      </div>
    );
  }

  return (
    <div style={styles.shell}>
      <style>{css}</style>

      {/* header */}
      <div style={styles.header}>
        <div style={styles.headerTop}>
          <div>
            <div style={styles.sessionName}>{session.name}</div>
            <div style={styles.sessionMeta}>
              {session.date || "No date set"}
              {(session.timeStart || session.timeEnd) && (
                <> &middot; {session.timeStart}{session.timeStart && session.timeEnd ? "\u2013" : ""}{session.timeEnd}</>
              )}
            </div>
          </div>
          <div style={styles.matchBadge}>
            <span style={styles.matchBadgeNum}>{matchCounter - 1}</span>
            <span style={styles.matchBadgeLabel}>matches played</span>
          </div>
        </div>
        <div style={styles.headerStats}>
          <div style={styles.headerStat}>
            <Users size={14} />
            <span>{checkedInCount} checked in</span>
          </div>
          <div style={styles.headerStat}>
            <div style={styles.courtDot} />
            <span>{COURTS_TOTAL - freeCourts}/{COURTS_TOTAL} courts busy</span>
          </div>
        </div>
      </div>

      {/* content */}
      <div style={styles.content}>
        {activeTab === "home" && (
          <HomeTab
            activeMatches={activeMatches}
            finishedMatches={finishedMatches}
            waitingPlayers={waitingPlayers}
            byId={byId}
            scoreDrafts={scoreDrafts}
            setScoreDrafts={setScoreDrafts}
            submitScore={submitScore}
            onShuffle={() => {
              setShuffleError("");
              setShuffleOpen(true);
            }}
            notCheckedInCount={notCheckedIn.length}
            goToPlayers={() => setActiveTab("players")}
          />
        )}

        {activeTab === "ranking" && (
          <RankingTab
            ranked={ranked}
            rankFilter={rankFilter}
            setRankFilter={setRankFilter}
            onSelect={(id) => setSelectedPlayerId(id)}
          />
        )}

        {activeTab === "players" && (
          <PlayersTab
            players={players}
            newPlayerName={newPlayerName}
            setNewPlayerName={setNewPlayerName}
            addPlayer={addPlayer}
            toggleCheckIn={toggleCheckIn}
            onSelect={(id) => setSelectedPlayerId(id)}
          />
        )}
      </div>

      {/* bottom nav */}
      <div style={styles.nav}>
        <NavButton icon={Home} label="Home" active={activeTab === "home"} onClick={() => setActiveTab("home")} />
        <NavButton icon={Trophy} label="Ranking" active={activeTab === "ranking"} onClick={() => setActiveTab("ranking")} />
        <NavButton icon={Users} label="Players" active={activeTab === "players"} onClick={() => setActiveTab("players")} />
      </div>

      {/* shuffle modal */}
      {shuffleOpen && (
        <ShuffleModal
          eligibleCount={eligiblePlayers.length}
          freeCourts={freeCourts}
          error={shuffleError}
          onPick={tryShuffle}
          onClose={() => setShuffleOpen(false)}
        />
      )}

      {/* player profile modal */}
      {selectedPlayer && (
        <ProfileModal player={selectedPlayer} rank={selectedRank} onClose={() => setSelectedPlayerId(null)} />
      )}
    </div>
  );
}

// ---------- setup screens ----------

function CreateTournamentScreen({ session, setSession, onNext }) {
  const set = (key) => (e) => setSession((s) => ({ ...s, [key]: e.target.value }));
  const canContinue = session.name.trim().length > 0;

  return (
    <div style={styles.setupWrap}>
      <div style={styles.setupStepLabel}>STEP 1 OF 2</div>
      <div style={styles.setupTitle}>Buat Turnamen</div>
      <div style={styles.setupSub}>Atur detail sesi padel kamu sebelum mengundang pemain.</div>

      <div style={styles.formGroup}>
        <label style={styles.formLabel}>Nama Turnamen</label>
        <input
          style={styles.formInput}
          placeholder="Contoh: Saturday Padel"
          value={session.name}
          onChange={set("name")}
          autoFocus
        />
      </div>

      <div style={styles.formGroup}>
        <label style={styles.formLabel}>Tanggal</label>
        <div style={styles.inputIconWrap}>
          <Calendar size={15} style={styles.inputIcon} />
          <input
            style={{ ...styles.formInput, paddingLeft: 34 }}
            placeholder="7 September 2026"
            value={session.date}
            onChange={set("date")}
          />
        </div>
      </div>

      <div style={styles.formRow}>
        <div style={{ ...styles.formGroup, flex: 1 }}>
          <label style={styles.formLabel}>Mulai</label>
          <input style={styles.formInput} placeholder="14:00" value={session.timeStart} onChange={set("timeStart")} />
        </div>
        <div style={{ ...styles.formGroup, flex: 1 }}>
          <label style={styles.formLabel}>Selesai</label>
          <input style={styles.formInput} placeholder="16:00" value={session.timeEnd} onChange={set("timeEnd")} />
        </div>
      </div>

      <div style={styles.formGroup}>
        <label style={styles.formLabel}>Jumlah Court</label>
        <div style={styles.stepperRow}>
          <button
            style={styles.stepperBtn}
            onClick={() => setSession((s) => ({ ...s, courtsTotal: Math.max(1, s.courtsTotal - 1) }))}
          >
            <Minus size={16} />
          </button>
          <span style={styles.stepperVal}>{session.courtsTotal}</span>
          <button
            style={styles.stepperBtn}
            onClick={() => setSession((s) => ({ ...s, courtsTotal: Math.min(4, s.courtsTotal + 1) }))}
          >
            <Plus size={16} />
          </button>
        </div>
      </div>

      <button style={{ ...styles.primaryBtn, ...(canContinue ? {} : styles.primaryBtnDisabled) }} disabled={!canContinue} onClick={onNext}>
        Lanjut: Tambah Pemain
        <ChevronRight size={16} />
      </button>
    </div>
  );
}

function AddPlayersScreen({ session, rosterDraft, setRosterDraft, rosterPlayers, addRosterPlayer, removeRosterPlayer, onBack, onStart }) {
  const minNeeded = 4;
  const canStart = rosterPlayers.length >= minNeeded;

  return (
    <div style={styles.setupWrap}>
      <button style={styles.backBtn} onClick={onBack}>
        <ChevronLeft size={16} />
        Edit turnamen
      </button>
      <div style={styles.setupStepLabel}>STEP 2 OF 2</div>
      <div style={styles.setupTitle}>Tambah Pemain</div>
      <div style={styles.setupSub}>
        {session.name} {session.date && `\u00b7 ${session.date}`}
      </div>

      <div style={styles.addRow}>
        <input
          style={styles.addInput}
          placeholder="Nama pemain"
          value={rosterDraft}
          onChange={(e) => setRosterDraft(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && addRosterPlayer()}
          autoFocus
        />
        <button style={styles.addBtn} onClick={addRosterPlayer}>
          <UserPlus size={16} />
        </button>
      </div>

      <div style={styles.rosterCountRow}>
        <span>{rosterPlayers.length} pemain ditambahkan</span>
        {!canStart && <span style={styles.rosterHint}>minimal {minNeeded} pemain</span>}
      </div>

      <div style={styles.rosterList}>
        {rosterPlayers.length === 0 && (
          <div style={styles.emptyBox}>Belum ada pemain. Ketik nama lalu tekan tombol tambah.</div>
        )}
        {rosterPlayers.map((p, i) => (
          <div key={p.id} style={styles.rosterRow}>
            <span style={styles.rosterNum}>{i + 1}</span>
            <span style={styles.rosterName}>{p.name}</span>
            <button style={styles.rosterRemove} onClick={() => removeRosterPlayer(p.id)}>
              <Trash2 size={14} />
            </button>
          </div>
        ))}
      </div>

      <button style={{ ...styles.primaryBtn, ...(canStart ? {} : styles.primaryBtnDisabled) }} disabled={!canStart} onClick={onStart}>
        Mulai Sesi
        <ChevronRight size={16} />
      </button>
    </div>
  );
}

// ---------- sub components ----------

function NavButton({ icon: Icon, label, active, onClick }) {
  return (
    <button style={{ ...styles.navBtn, ...(active ? styles.navBtnActive : {}) }} onClick={onClick}>
      <Icon size={20} strokeWidth={active ? 2.4 : 1.8} />
      <span style={styles.navLabel}>{label}</span>
    </button>
  );
}

function HomeTab({
  activeMatches,
  finishedMatches,
  waitingPlayers,
  byId,
  scoreDrafts,
  setScoreDrafts,
  submitScore,
  onShuffle,
  notCheckedInCount,
  goToPlayers,
}) {
  return (
    <div>
      <div style={styles.sectionHead}>
        <span style={styles.sectionTitle}>Live Courts</span>
        <span style={styles.sectionCount}>{activeMatches.length}</span>
      </div>

      {activeMatches.length === 0 && (
        <div style={styles.emptyBox}>Belum ada match berjalan. Tekan shuffle untuk memulai.</div>
      )}

      {activeMatches.map((m) => {
        const draft = scoreDrafts[m.id] || { a: "", b: "" };
        return (
          <div key={m.id} style={styles.matchCard}>
            <div style={styles.matchTop}>
              <span style={styles.courtLabel}>COURT {m.court}</span>
              <span style={styles.playingTag}>PLAYING</span>
            </div>
            <div style={styles.teamRow}>
              <div style={styles.teamNames}>{m.teamA.map((id) => byId[id].name).join(" & ")}</div>
              <input
                style={styles.scoreInput}
                inputMode="numeric"
                placeholder="–"
                value={draft.a}
                onChange={(e) =>
                  setScoreDrafts((prev) => ({ ...prev, [m.id]: { ...draft, a: e.target.value.replace(/[^0-9]/g, "") } }))
                }
              />
            </div>
            <div style={styles.vsDivider}>vs</div>
            <div style={styles.teamRow}>
              <div style={styles.teamNames}>{m.teamB.map((id) => byId[id].name).join(" & ")}</div>
              <input
                style={styles.scoreInput}
                inputMode="numeric"
                placeholder="–"
                value={draft.b}
                onChange={(e) =>
                  setScoreDrafts((prev) => ({ ...prev, [m.id]: { ...draft, b: e.target.value.replace(/[^0-9]/g, "") } }))
                }
              />
            </div>
            <button
              style={{ ...styles.submitBtn, ...(draft.a === "" || draft.b === "" ? styles.submitBtnDisabled : {}) }}
              disabled={draft.a === "" || draft.b === ""}
              onClick={() => submitScore(m.id)}
            >
              Submit Score
            </button>
          </div>
        );
      })}

      <div style={styles.shuffleBtnWrap}>
        <button style={styles.shuffleBtn} onClick={onShuffle}>
          <Shuffle size={18} />
          Shuffle Match
        </button>
      </div>

      <div style={styles.sectionHead}>
        <span style={styles.sectionTitle}>Waiting</span>
        <span style={styles.sectionCount}>{waitingPlayers.length}</span>
      </div>
      {waitingPlayers.length === 0 ? (
        <div style={styles.emptyBox}>Tidak ada pemain menunggu.</div>
      ) : (
        <div style={styles.chipWrap}>
          {waitingPlayers.map((p) => (
            <div key={p.id} style={styles.chip}>
              <span>{p.name}</span>
              <span style={styles.chipPlayed}>{p.played}</span>
            </div>
          ))}
        </div>
      )}

      {notCheckedInCount > 0 && (
        <button style={styles.checkinNudge} onClick={goToPlayers}>
          <Clock size={14} />
          {notCheckedInCount} pemain belum check-in
          <ChevronRight size={14} />
        </button>
      )}

      {finishedMatches.length > 0 && (
        <>
          <div style={styles.sectionHead}>
            <span style={styles.sectionTitle}>Recent Matches</span>
          </div>
          {finishedMatches.slice(0, 5).map((m) => (
            <div key={m.id} style={styles.recentRow}>
              <span style={styles.recentCourt}>C{m.court}</span>
              <span style={styles.recentTeams}>
                {m.teamA.map((id) => byId[id].name).join(" & ")}
                <span style={styles.recentScore}> {m.scoreA}–{m.scoreB} </span>
                {m.teamB.map((id) => byId[id].name).join(" & ")}
              </span>
            </div>
          ))}
        </>
      )}
    </div>
  );
}

function ShuffleModal({ eligibleCount, freeCourts, error, onPick, onClose }) {
  const options = [1, 2, 3, 4];
  return (
    <div style={styles.overlay} onClick={onClose}>
      <div style={styles.sheet} onClick={(e) => e.stopPropagation()}>
        <div style={styles.sheetHead}>
          <span style={styles.sheetTitle}>How many matches?</span>
          <button style={styles.iconBtn} onClick={onClose}>
            <X size={18} />
          </button>
        </div>
        <div style={styles.sheetSub}>{eligibleCount} pemain siap &middot; {freeCourts} court kosong</div>
        <div style={styles.optionGrid}>
          {options.map((n) => {
            const disabled = eligibleCount < n * 4 || freeCourts < n;
            return (
              <button
                key={n}
                style={{ ...styles.optionBtn, ...(disabled ? styles.optionBtnDisabled : {}) }}
                disabled={disabled}
                onClick={() => onPick(n)}
              >
                <span style={styles.optionNum}>{n}</span>
                <span style={styles.optionSub}>{n * 4} players</span>
              </button>
            );
          })}
        </div>
        {error && <div style={styles.errorBox}>{error}</div>}
      </div>
    </div>
  );
}

function RankingTab({ ranked, rankFilter, setRankFilter, onSelect }) {
  const filters = [
    { key: "points", label: "Points" },
    { key: "wins", label: "Wins" },
    { key: "winRate", label: "Win Rate" },
  ];
  return (
    <div>
      <div style={styles.filterRow}>
        {filters.map((f) => (
          <button
            key={f.key}
            style={{ ...styles.filterChip, ...(rankFilter === f.key ? styles.filterChipActive : {}) }}
            onClick={() => setRankFilter(f.key)}
          >
            {f.label}
          </button>
        ))}
      </div>
      <div style={styles.ptsNote}>PTS = 3×Wins + Selisih Game</div>
      {ranked.map((p, i) => (
        <button key={p.id} style={styles.rankRow} onClick={() => onSelect(p.id)}>
          <span style={{ ...styles.rankNum, ...(i < 3 ? styles.rankNumTop : {}) }}>{i + 1}</span>
          <div style={styles.rankInfo}>
            <span style={styles.rankName}>{p.name}</span>
            <span style={styles.rankSub}>{p.played} played &middot; {p.wins}W {p.losses}L</span>
          </div>
          <div style={styles.rankStat}>
            <span style={styles.rankStatNum}>
              {rankFilter === "winRate" ? `${p.winRate}%` : rankFilter === "wins" ? p.wins : p.points}
            </span>
            <span style={styles.rankStatLabel}>{rankFilter === "winRate" ? "rate" : rankFilter === "wins" ? "wins" : "pts"}</span>
          </div>
        </button>
      ))}
    </div>
  );
}

function PlayersTab({ players, newPlayerName, setNewPlayerName, addPlayer, toggleCheckIn, onSelect }) {
  const sorted = [...players].sort((a, b) => a.name.localeCompare(b.name));
  return (
    <div>
      <div style={styles.addRow}>
        <input
          style={styles.addInput}
          placeholder="Nama pemain baru"
          value={newPlayerName}
          onChange={(e) => setNewPlayerName(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && addPlayer()}
        />
        <button style={styles.addBtn} onClick={addPlayer}>
          <UserPlus size={16} />
        </button>
      </div>

      {sorted.map((p) => (
        <div key={p.id} style={styles.playerRow}>
          <button style={styles.playerRowMain} onClick={() => onSelect(p.id)}>
            <span
              style={{
                ...styles.statusDot,
                background:
                  p.status === "playing" ? "var(--accent)" : p.checkedIn ? "#5FA8D3" : "#43607A",
              }}
            />
            <div style={styles.playerRowInfo}>
              <span style={styles.playerRowName}>{p.name}</span>
              <span style={styles.playerRowMeta}>
                {p.status === "playing" ? "Playing" : p.checkedIn ? "Ready" : "Not checked in"} &middot; {p.played} played
              </span>
            </div>
          </button>
          <button
            style={{ ...styles.checkBtn, ...(p.checkedIn ? styles.checkBtnActive : {}) }}
            disabled={p.status === "playing"}
            onClick={() => toggleCheckIn(p.id)}
          >
            {p.checkedIn ? <Check size={14} /> : <Plus size={14} />}
          </button>
        </div>
      ))}
    </div>
  );
}

function ProfileModal({ player, rank, onClose }) {
  const winRate = player.played > 0 ? Math.round((player.wins / player.played) * 100) : 0;
  const points = player.wins * 3 + (player.scoreFor - player.scoreAgainst);
  return (
    <div style={styles.overlay} onClick={onClose}>
      <div style={styles.sheet} onClick={(e) => e.stopPropagation()}>
        <div style={styles.sheetHead}>
          <span style={styles.sheetTitle}>{player.name}</span>
          <button style={styles.iconBtn} onClick={onClose}>
            <X size={18} />
          </button>
        </div>
        <div style={styles.profileRankBadge}>Rank #{rank}</div>
        <div style={styles.statsGrid}>
          <Stat label="Played" value={player.played} />
          <Stat label="Wins" value={player.wins} />
          <Stat label="Losses" value={player.losses} />
          <Stat label="Points" value={points} />
          <Stat label="Win Rate" value={`${winRate}%`} />
          <Stat label="Diff" value={player.scoreFor - player.scoreAgainst} />
        </div>
        <div style={styles.historyLabel}>Match History</div>
        <div style={styles.historyList}>
          {player.history.length === 0 && <div style={styles.emptyBox}>Belum ada pertandingan.</div>}
          {[...player.history].reverse().map((h, i) => (
            <div key={i} style={styles.historyRow}>
              <span style={{ ...styles.historyResult, color: h.result === "W" ? "var(--accent)" : "#E2717A" }}>
                {h.result}
              </span>
              <div style={styles.historyMid}>
                <span style={styles.historyLine}>with {h.partner} vs {h.opponents.join(" & ")}</span>
                <span style={styles.historySub}>Court {h.court} &middot; Match #{h.matchNumber}</span>
              </div>
              <span style={styles.historyScore}>{h.score}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function Stat({ label, value }) {
  return (
    <div style={styles.statBox}>
      <span style={styles.statValue}>{value}</span>
      <span style={styles.statLabel}>{label}</span>
    </div>
  );
}

// ---------- styles ----------
const styles = {
  setupWrap: {
    height: "100%",
    overflowY: "auto",
    padding: "28px 22px 32px",
    display: "flex",
    flexDirection: "column",
  },
  setupStepLabel: { fontSize: 11, fontWeight: 800, letterSpacing: 1.4, color: "var(--accent)", marginBottom: 10 },
  setupTitle: { fontSize: 24, fontWeight: 800, letterSpacing: -0.4, marginBottom: 6 },
  setupSub: { fontSize: 13, color: "var(--muted)", marginBottom: 26, lineHeight: 1.5 },
  backBtn: {
    display: "flex",
    alignItems: "center",
    gap: 4,
    background: "none",
    border: "none",
    color: "var(--muted)",
    fontSize: 12.5,
    fontWeight: 700,
    marginBottom: 18,
    padding: 0,
    alignSelf: "flex-start",
  },
  formGroup: { marginBottom: 16 },
  formRow: { display: "flex", gap: 12 },
  formLabel: { display: "block", fontSize: 11.5, fontWeight: 700, color: "var(--muted)", marginBottom: 6, letterSpacing: 0.2 },
  formInput: {
    width: "100%",
    background: "var(--surface)",
    border: "1px solid var(--line)",
    borderRadius: 4,
    padding: "12px 14px",
    color: "var(--text)",
    fontSize: 14.5,
  },
  inputIconWrap: { position: "relative" },
  inputIcon: { position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)", color: "var(--muted)" },
  stepperRow: { display: "flex", alignItems: "center", gap: 18 },
  stepperBtn: {
    width: 38,
    height: 38,
    borderRadius: 4,
    border: "1px solid var(--line)",
    background: "var(--surface)",
    color: "var(--accent)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
  },
  stepperVal: { fontSize: 22, fontWeight: 800, fontVariantNumeric: "tabular-nums", minWidth: 20, textAlign: "center" },
  primaryBtn: {
    marginTop: "auto",
    width: "100%",
    padding: "15px 0",
    background: "var(--accent)",
    color: "var(--bg)",
    border: "none",
    borderRadius: 4,
    fontWeight: 800,
    fontSize: 14.5,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
  },
  primaryBtnDisabled: { background: "var(--line)", color: "var(--muted)" },
  rosterCountRow: {
    display: "flex",
    justifyContent: "space-between",
    fontSize: 12,
    color: "var(--muted)",
    marginBottom: 10,
  },
  rosterHint: { color: "#E2B23D" },
  rosterList: { flex: 1, marginBottom: 20, display: "flex", flexDirection: "column", gap: 8, minHeight: 40 },
  rosterRow: {
    display: "flex",
    alignItems: "center",
    gap: 12,
    background: "var(--surface)",
    border: "1px solid var(--line)",
    borderRadius: 4,
    padding: "10px 12px",
  },
  rosterNum: { fontSize: 11, fontWeight: 800, color: "var(--muted)", width: 16 },
  rosterName: { flex: 1, fontSize: 14, fontWeight: 600 },
  rosterRemove: { background: "none", border: "none", color: "var(--muted)" },
  shell: {
    maxWidth: 420,
    margin: "0 auto",
    height: "100vh",
    display: "flex",
    flexDirection: "column",
    background: "var(--bg)",
    color: "var(--text)",
    fontFamily:
      "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
    position: "relative",
    overflow: "hidden",
  },
  header: {
    padding: "18px 18px 12px",
    background: "var(--surface)",
    borderBottom: "1px solid var(--line)",
    flexShrink: 0,
  },
  headerTop: { display: "flex", justifyContent: "space-between", alignItems: "flex-start" },
  sessionName: { fontSize: 19, fontWeight: 700, letterSpacing: -0.3 },
  sessionMeta: { fontSize: 12.5, color: "var(--muted)", marginTop: 2 },
  matchBadge: { textAlign: "right" },
  matchBadgeNum: {
    display: "block",
    fontSize: 22,
    fontWeight: 800,
    color: "var(--accent)",
    fontVariantNumeric: "tabular-nums",
    lineHeight: 1,
  },
  matchBadgeLabel: { fontSize: 10, color: "var(--muted)", textTransform: "lowercase" },
  headerStats: { display: "flex", gap: 14, marginTop: 12 },
  headerStat: { display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: "var(--muted)" },
  courtDot: { width: 8, height: 8, borderRadius: 2, background: "var(--accent)" },
  content: { flex: 1, overflowY: "auto", padding: "14px 16px 90px" },

  sectionHead: { display: "flex", alignItems: "center", gap: 8, margin: "18px 0 10px" },
  sectionTitle: { fontSize: 13, fontWeight: 700, letterSpacing: 0.2, color: "var(--text)" },
  sectionCount: {
    fontSize: 11,
    color: "var(--bg)",
    background: "var(--muted)",
    borderRadius: 20,
    padding: "1px 7px",
    fontWeight: 700,
  },
  emptyBox: {
    fontSize: 13,
    color: "var(--muted)",
    background: "var(--surface)",
    padding: "16px 14px",
    borderRadius: 4,
    border: "1px dashed var(--line)",
  },

  matchCard: {
    background: "var(--surface)",
    borderLeft: "3px solid var(--accent)",
    borderRadius: 4,
    padding: 14,
    marginBottom: 12,
  },
  matchTop: { display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 },
  courtLabel: { fontSize: 11, fontWeight: 800, letterSpacing: 0.8, color: "var(--muted)" },
  playingTag: {
    fontSize: 10,
    fontWeight: 800,
    letterSpacing: 0.6,
    color: "var(--bg)",
    background: "var(--accent)",
    padding: "2px 8px",
    borderRadius: 20,
  },
  teamRow: { display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10 },
  teamNames: { fontSize: 14.5, fontWeight: 600, flex: 1 },
  scoreInput: {
    width: 44,
    height: 38,
    background: "var(--bg)",
    border: "1px solid var(--line)",
    borderRadius: 4,
    color: "var(--accent)",
    fontSize: 18,
    fontWeight: 800,
    textAlign: "center",
    fontVariantNumeric: "tabular-nums",
  },
  vsDivider: { fontSize: 10, color: "var(--muted)", textAlign: "center", margin: "6px 0", letterSpacing: 1 },
  submitBtn: {
    width: "100%",
    marginTop: 12,
    padding: "10px 0",
    background: "var(--accent)",
    color: "var(--bg)",
    border: "none",
    borderRadius: 4,
    fontWeight: 800,
    fontSize: 13,
  },
  submitBtnDisabled: { background: "var(--line)", color: "var(--muted)" },

  shuffleBtnWrap: { margin: "16px 0 6px" },
  shuffleBtn: {
    width: "100%",
    padding: "13px 0",
    background: "transparent",
    color: "var(--accent)",
    border: "1.5px solid var(--accent)",
    borderRadius: 4,
    fontWeight: 800,
    fontSize: 14,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    letterSpacing: 0.3,
  },

  chipWrap: { display: "flex", flexWrap: "wrap", gap: 8 },
  chip: {
    display: "flex",
    alignItems: "center",
    gap: 6,
    background: "var(--surface)",
    border: "1px solid var(--line)",
    borderRadius: 20,
    padding: "6px 6px 6px 12px",
    fontSize: 13,
  },
  chipPlayed: {
    background: "var(--line)",
    borderRadius: "50%",
    width: 20,
    height: 20,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontSize: 10.5,
    fontWeight: 800,
  },

  checkinNudge: {
    width: "100%",
    marginTop: 16,
    display: "flex",
    alignItems: "center",
    gap: 8,
    background: "rgba(215,255,61,0.08)",
    border: "1px solid rgba(215,255,61,0.3)",
    color: "var(--accent)",
    borderRadius: 4,
    padding: "10px 12px",
    fontSize: 12.5,
    fontWeight: 600,
  },

  recentRow: {
    display: "flex",
    alignItems: "center",
    gap: 10,
    padding: "9px 0",
    borderBottom: "1px solid var(--line)",
    fontSize: 12.5,
  },
  recentCourt: { color: "var(--muted)", fontWeight: 700, fontSize: 11, width: 22 },
  recentTeams: { color: "var(--text)" },
  recentScore: { color: "var(--accent)", fontWeight: 800 },

  nav: {
    display: "flex",
    borderTop: "1px solid var(--line)",
    background: "var(--surface)",
    flexShrink: 0,
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
  },
  navBtn: {
    flex: 1,
    background: "none",
    border: "none",
    padding: "10px 0 12px",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: 4,
    color: "var(--muted)",
  },
  navBtnActive: { color: "var(--accent)" },
  navLabel: { fontSize: 10.5, fontWeight: 700 },

  overlay: {
    position: "absolute",
    inset: 0,
    background: "rgba(5,15,22,0.7)",
    display: "flex",
    alignItems: "flex-end",
    zIndex: 10,
  },
  sheet: {
    width: "100%",
    maxHeight: "82%",
    overflowY: "auto",
    background: "var(--surface)",
    borderTop: "1px solid var(--line)",
    borderRadius: "10px 10px 0 0",
    padding: 18,
  },
  sheetHead: { display: "flex", justifyContent: "space-between", alignItems: "center" },
  sheetTitle: { fontSize: 17, fontWeight: 800 },
  sheetSub: { fontSize: 12, color: "var(--muted)", marginTop: 4, marginBottom: 16 },
  iconBtn: { background: "var(--line)", border: "none", borderRadius: "50%", width: 28, height: 28, color: "var(--text)", display: "flex", alignItems: "center", justifyContent: "center" },

  optionGrid: { display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 },
  optionBtn: {
    background: "var(--bg)",
    border: "1px solid var(--line)",
    borderRadius: 4,
    padding: "16px 0",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: 4,
  },
  optionBtnDisabled: { opacity: 0.35 },
  optionNum: { fontSize: 26, fontWeight: 800, color: "var(--accent)" },
  optionSub: { fontSize: 11, color: "var(--muted)" },
  errorBox: {
    marginTop: 14,
    fontSize: 12.5,
    color: "#E2717A",
    background: "rgba(226,113,122,0.1)",
    border: "1px solid rgba(226,113,122,0.3)",
    borderRadius: 4,
    padding: "10px 12px",
  },

  filterRow: { display: "flex", gap: 8, marginBottom: 6 },
  filterChip: {
    padding: "7px 14px",
    borderRadius: 20,
    border: "1px solid var(--line)",
    background: "transparent",
    color: "var(--muted)",
    fontSize: 12.5,
    fontWeight: 700,
  },
  filterChipActive: { background: "var(--accent)", color: "var(--bg)", borderColor: "var(--accent)" },
  ptsNote: { fontSize: 10.5, color: "var(--muted)", margin: "6px 2px 12px" },

  rankRow: {
    width: "100%",
    display: "flex",
    alignItems: "center",
    gap: 12,
    background: "var(--surface)",
    border: "1px solid var(--line)",
    borderRadius: 4,
    padding: "12px 14px",
    marginBottom: 8,
  },
  rankNum: { fontSize: 16, fontWeight: 800, color: "var(--muted)", width: 20, fontVariantNumeric: "tabular-nums" },
  rankNumTop: { color: "var(--accent)" },
  rankInfo: { flex: 1, display: "flex", flexDirection: "column", alignItems: "flex-start" },
  rankName: { fontSize: 14.5, fontWeight: 700 },
  rankSub: { fontSize: 11.5, color: "var(--muted)", marginTop: 2 },
  rankStat: { display: "flex", flexDirection: "column", alignItems: "flex-end" },
  rankStatNum: { fontSize: 17, fontWeight: 800, color: "var(--text)", fontVariantNumeric: "tabular-nums" },
  rankStatLabel: { fontSize: 9.5, color: "var(--muted)", textTransform: "uppercase" },

  addRow: { display: "flex", gap: 8, marginBottom: 16 },
  addInput: {
    flex: 1,
    background: "var(--surface)",
    border: "1px solid var(--line)",
    borderRadius: 4,
    padding: "11px 12px",
    color: "var(--text)",
    fontSize: 13.5,
  },
  addBtn: { width: 42, background: "var(--accent)", border: "none", borderRadius: 4, color: "var(--bg)", display: "flex", alignItems: "center", justifyContent: "center" },

  playerRow: {
    display: "flex",
    alignItems: "center",
    gap: 10,
    padding: "10px 0",
    borderBottom: "1px solid var(--line)",
  },
  playerRowMain: { flex: 1, display: "flex", alignItems: "center", gap: 10, background: "none", border: "none", textAlign: "left" },
  statusDot: { width: 8, height: 8, borderRadius: "50%", flexShrink: 0 },
  playerRowInfo: { display: "flex", flexDirection: "column", alignItems: "flex-start" },
  playerRowName: { fontSize: 14, fontWeight: 700, color: "var(--text)" },
  playerRowMeta: { fontSize: 11, color: "var(--muted)", marginTop: 1 },
  checkBtn: {
    width: 30,
    height: 30,
    borderRadius: "50%",
    border: "1px solid var(--line)",
    background: "transparent",
    color: "var(--muted)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    flexShrink: 0,
  },
  checkBtnActive: { background: "var(--accent)", borderColor: "var(--accent)", color: "var(--bg)" },

  profileRankBadge: {
    display: "inline-block",
    fontSize: 11,
    fontWeight: 800,
    color: "var(--bg)",
    background: "var(--accent)",
    padding: "3px 10px",
    borderRadius: 20,
    marginBottom: 14,
  },
  statsGrid: { display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8, marginBottom: 20 },
  statBox: {
    background: "var(--bg)",
    border: "1px solid var(--line)",
    borderRadius: 4,
    padding: "10px 0",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
  },
  statValue: { fontSize: 18, fontWeight: 800, color: "var(--accent)", fontVariantNumeric: "tabular-nums" },
  statLabel: { fontSize: 10, color: "var(--muted)", marginTop: 2 },
  historyLabel: { fontSize: 12, fontWeight: 700, color: "var(--muted)", marginBottom: 8, letterSpacing: 0.3 },
  historyList: { display: "flex", flexDirection: "column", gap: 8, paddingBottom: 10 },
  historyRow: { display: "flex", alignItems: "center", gap: 10, background: "var(--bg)", borderRadius: 4, padding: "9px 12px" },
  historyResult: { fontWeight: 800, fontSize: 13, width: 16 },
  historyMid: { flex: 1, display: "flex", flexDirection: "column" },
  historyLine: { fontSize: 12.5 },
  historySub: { fontSize: 10.5, color: "var(--muted)", marginTop: 1 },
  historyScore: { fontWeight: 800, fontSize: 13, fontVariantNumeric: "tabular-nums" },
};

const css = `
  :root {
    --bg: #0B2536;
    --surface: #123249;
    --line: #1E4A5D;
    --accent: #D7FF3D;
    --text: #F2F3EA;
    --muted: #6F93A8;
  }
  * { box-sizing: border-box; }
  input:focus, button:focus { outline: 2px solid var(--accent); outline-offset: 1px; }
  button { cursor: pointer; font-family: inherit; }
  ::placeholder { color: var(--muted); }
`;
