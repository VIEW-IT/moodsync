// Convert mood to numeric score (for charting)
function moodScore(m) { return m === 'bad' ? 1 : m === 'meh' ? 2 : 3; }

// Last 7 day ISO labels
function last7() {
  const out = [];
  const d = new Date();
  for (let i = 0; i < 7; i++) {
    const t = new Date(d);
    t.setDate(d.getDate() - i);
    out.unshift(t.toISOString().slice(0, 10));
  }
  return out;
}

// Render weekly chart into a <canvas id="...">
function renderWeeklyChart(canvasId, entries) {
  const labels = last7();
  const map = new Map(labels.map(l => [l, null]));
  for (const e of entries) if (map.has(e.date)) map.set(e.date, moodScore(e.mood));
  const data = labels.map(l => map.get(l) ?? null);

  const canvas = document.getElementById(canvasId);
  if (!canvas) return;

  // Destroy previous instance if we re-render
  if (canvas.__msChart) canvas.__msChart.destroy();

  // Chart comes from Chart.js loaded in the HTML
  canvas.__msChart = new Chart(canvas, {
    type: 'line',
    data: {
      labels: labels.map(l => l.slice(5)),
      datasets: [{
        label: 'Mood (1=bad, 3=good)',
        data,
        spanGaps: true,
        tension: 0.35
      }]
    },
    options: {
      scales: {
        y: { min: 1, max: 3, ticks: { stepSize: 1 } }
      }
    }
  });
}
