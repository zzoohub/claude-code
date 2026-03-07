# D3.js Interactive Charts

> Framework-agnostic. Works in vanilla JS, React, SolidJS, Svelte, Vue — D3 operates on the DOM directly, like GSAP.

## Installation

```bash
bun add d3
bun add -d @types/d3
```

## Setup

```ts
// lib/d3.ts — centralized import (tree-shake by importing only what you need)
export {
  select,
  selectAll,
  create,
} from "d3-selection";
export {
  scaleLinear,
  scaleBand,
  scaleOrdinal,
  scaleTime,
  scaleUtc,
} from "d3-scale";
export { axisBottom, axisLeft } from "d3-axis";
export {
  line,
  area,
  arc,
  pie,
  curveMonotoneX,
  curveBumpX,
  curveNatural,
} from "d3-shape";
export { max, min, extent, sum, bisector } from "d3-array";
export { format } from "d3-format";
export { transition } from "d3-transition"; // side-effect: extends selection with .transition()
export { zoom, zoomIdentity } from "d3-zoom";
export { brush, brushX, brushY } from "d3-brush";
export { pointer } from "d3-selection";
export { schemeCategory10, schemeTableau10 } from "d3-scale-chromatic";

// Full import alternative (simpler, larger bundle):
// export * as d3 from "d3";
```

Always import from this file:
```ts
import { select, scaleLinear, axisBottom, line } from "@/lib/d3";
```

## Core Concepts

### Chart Factory Pattern

Every chart is a function that takes a container, data, and options — returns a cleanup function. Same pattern as GSAP in this skill.

```ts
interface ChartOptions {
  width?: number;
  height?: number;
  margin?: { top: number; right: number; bottom: number; left: number };
}

const defaults: Required<ChartOptions> = {
  width: 640,
  height: 400,
  margin: { top: 20, right: 20, bottom: 30, left: 40 },
};

// Every chart factory follows this signature
type ChartFactory<T> = (
  container: HTMLElement,
  data: T[],
  options?: ChartOptions
) => { update: (newData: T[]) => void; destroy: () => void };
```

### Responsive Container

Wrap charts in a responsive container that observes size changes:

```ts
function createResponsiveChart<T>(
  container: HTMLElement,
  factory: ChartFactory<T>,
  data: T[],
  options?: Omit<ChartOptions, "width" | "height">
) {
  let chart: ReturnType<ChartFactory<T>> | null = null;

  const observer = new ResizeObserver((entries) => {
    const { width, height } = entries[0].contentRect;
    if (width === 0 || height === 0) return;

    chart?.destroy();
    chart = factory(container, data, { ...options, width, height });
  });

  observer.observe(container);

  return {
    update: (newData: T[]) => {
      data = newData;
      chart?.update(newData);
    },
    destroy: () => {
      observer.disconnect();
      chart?.destroy();
    },
  };
}
```

## Chart Patterns

### Bar Chart

```ts
import {
  select, scaleBand, scaleLinear, axisBottom, axisLeft, max,
} from "@/lib/d3";

interface BarDatum {
  label: string;
  value: number;
}

function createBarChart(
  container: HTMLElement,
  data: BarDatum[],
  options?: ChartOptions
) {
  const { width, height, margin } = { ...defaults, ...options };
  const innerW = width - margin.left - margin.right;
  const innerH = height - margin.top - margin.bottom;

  // Clear previous
  select(container).select("svg").remove();

  const svg = select(container)
    .append("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("viewBox", `0 0 ${width} ${height}`)
    .attr("role", "img")
    .append("g")
    .attr("transform", `translate(${margin.left},${margin.top})`);

  const x = scaleBand<string>()
    .domain(data.map((d) => d.label))
    .range([0, innerW])
    .padding(0.2);

  const y = scaleLinear()
    .domain([0, max(data, (d) => d.value) ?? 0])
    .nice()
    .range([innerH, 0]);

  // Axes
  svg
    .append("g")
    .attr("class", "x-axis")
    .attr("transform", `translate(0,${innerH})`)
    .call(axisBottom(x).tickSizeOuter(0));

  svg.append("g").attr("class", "y-axis").call(axisLeft(y).ticks(5));

  // Bars — animate from bottom on enter
  svg
    .selectAll(".bar")
    .data(data, (d: any) => d.label)
    .join("rect")
    .attr("class", "bar")
    .attr("x", (d) => x(d.label)!)
    .attr("width", x.bandwidth())
    .attr("y", innerH)
    .attr("height", 0)
    .attr("fill", "currentColor")
    .attr("rx", 2)
    .transition()
    .duration(600)
    .delay((_, i) => i * 50)
    .attr("y", (d) => y(d.value))
    .attr("height", (d) => innerH - y(d.value));

  function update(newData: BarDatum[]) {
    x.domain(newData.map((d) => d.label));
    y.domain([0, max(newData, (d) => d.value) ?? 0]).nice();

    svg.select<SVGGElement>(".x-axis").transition().duration(400).call(axisBottom(x).tickSizeOuter(0));
    svg.select<SVGGElement>(".y-axis").transition().duration(400).call(axisLeft(y).ticks(5));

    svg
      .selectAll<SVGRectElement, BarDatum>(".bar")
      .data(newData, (d) => d.label)
      .join(
        (enter) =>
          enter
            .append("rect")
            .attr("class", "bar")
            .attr("x", (d) => x(d.label)!)
            .attr("width", x.bandwidth())
            .attr("y", innerH)
            .attr("height", 0)
            .attr("fill", "currentColor")
            .attr("rx", 2)
            .call((e) =>
              e
                .transition()
                .duration(400)
                .attr("y", (d) => y(d.value))
                .attr("height", (d) => innerH - y(d.value))
            ),
        (upd) =>
          upd.call((u) =>
            u
              .transition()
              .duration(400)
              .attr("x", (d) => x(d.label)!)
              .attr("width", x.bandwidth())
              .attr("y", (d) => y(d.value))
              .attr("height", (d) => innerH - y(d.value))
          ),
        (exit) =>
          exit.call((e) =>
            e
              .transition()
              .duration(300)
              .attr("height", 0)
              .attr("y", innerH)
              .remove()
          )
      );
  }

  return {
    update,
    destroy: () => {
      select(container).select("svg").remove();
    },
  };
}
```

### Line Chart

```ts
import {
  select, scaleLinear, scaleUtc, axisBottom, axisLeft,
  line as d3Line, curveMonotoneX, extent, bisector, pointer,
} from "@/lib/d3";

interface TimeSeriesDatum {
  date: Date;
  value: number;
}

function createLineChart(
  container: HTMLElement,
  data: TimeSeriesDatum[],
  options?: ChartOptions
) {
  const { width, height, margin } = { ...defaults, ...options };
  const innerW = width - margin.left - margin.right;
  const innerH = height - margin.top - margin.bottom;

  select(container).select("svg").remove();

  const svg = select(container)
    .append("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("viewBox", `0 0 ${width} ${height}`)
    .attr("role", "img");

  const g = svg
    .append("g")
    .attr("transform", `translate(${margin.left},${margin.top})`);

  const x = scaleUtc()
    .domain(extent(data, (d) => d.date) as [Date, Date])
    .range([0, innerW]);

  const y = scaleLinear()
    .domain(extent(data, (d) => d.value) as [number, number])
    .nice()
    .range([innerH, 0]);

  g.append("g")
    .attr("transform", `translate(0,${innerH})`)
    .call(axisBottom(x).ticks(6));

  g.append("g").call(axisLeft(y).ticks(5));

  const lineGen = d3Line<TimeSeriesDatum>()
    .x((d) => x(d.date))
    .y((d) => y(d.value))
    .curve(curveMonotoneX);

  // Draw line with stroke-dasharray animation
  const path = g
    .append("path")
    .datum(data)
    .attr("fill", "none")
    .attr("stroke", "currentColor")
    .attr("stroke-width", 2)
    .attr("d", lineGen);

  const totalLength = (path.node() as SVGPathElement).getTotalLength();
  path
    .attr("stroke-dasharray", `${totalLength} ${totalLength}`)
    .attr("stroke-dashoffset", totalLength)
    .transition()
    .duration(1200)
    .attr("stroke-dashoffset", 0);

  // Interactive crosshair tooltip
  const tooltipLine = g
    .append("line")
    .attr("stroke", "currentColor")
    .attr("stroke-width", 1)
    .attr("stroke-dasharray", "4 2")
    .attr("opacity", 0)
    .attr("y1", 0)
    .attr("y2", innerH);

  const tooltipDot = g
    .append("circle")
    .attr("r", 4)
    .attr("fill", "currentColor")
    .attr("opacity", 0);

  const tooltipText = g
    .append("text")
    .attr("font-size", 12)
    .attr("text-anchor", "middle")
    .attr("opacity", 0);

  const bisect = bisector<TimeSeriesDatum, Date>((d) => d.date).left;

  svg.on("pointerenter pointermove", (event: PointerEvent) => {
    const [mx] = pointer(event, g.node()!);
    const date = x.invert(mx);
    const idx = bisect(data, date, 1);
    const d0 = data[idx - 1];
    const d1 = data[idx];
    if (!d0 || !d1) return;
    const d = +date - +d0.date > +d1.date - +date ? d1 : d0;
    const px = x(d.date);
    const py = y(d.value);

    tooltipLine.attr("x1", px).attr("x2", px).attr("opacity", 1);
    tooltipDot.attr("cx", px).attr("cy", py).attr("opacity", 1);
    tooltipText.attr("x", px).attr("y", py - 12).text(d.value).attr("opacity", 1);
  });

  svg.on("pointerleave", () => {
    tooltipLine.attr("opacity", 0);
    tooltipDot.attr("opacity", 0);
    tooltipText.attr("opacity", 0);
  });

  return {
    update: (newData: TimeSeriesDatum[]) => {
      x.domain(extent(newData, (d) => d.date) as [Date, Date]);
      y.domain(extent(newData, (d) => d.value) as [number, number]).nice();
      path.datum(newData).transition().duration(600).attr("d", lineGen);
    },
    destroy: () => {
      select(container).select("svg").remove();
    },
  };
}
```

### Donut Chart

```ts
import { select, arc as d3Arc, pie as d3Pie, scaleOrdinal, schemeTableau10 } from "@/lib/d3";

interface SliceDatum {
  label: string;
  value: number;
}

function createDonutChart(
  container: HTMLElement,
  data: SliceDatum[],
  options?: ChartOptions
) {
  const { width, height } = { ...defaults, ...options };
  const radius = Math.min(width, height) / 2;
  const innerRadius = radius * 0.55;

  select(container).select("svg").remove();

  const svg = select(container)
    .append("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("viewBox", `${-width / 2} ${-height / 2} ${width} ${height}`)
    .attr("role", "img");

  const color = scaleOrdinal<string>().range(schemeTableau10);

  const pieGen = d3Pie<SliceDatum>()
    .value((d) => d.value)
    .sort(null)
    .padAngle(0.02);

  const arcGen = d3Arc<any>().innerRadius(innerRadius).outerRadius(radius);

  const arcs = svg
    .selectAll(".arc")
    .data(pieGen(data))
    .join("path")
    .attr("class", "arc")
    .attr("fill", (_, i) => color(String(i)))
    .attr("stroke", "white")
    .attr("stroke-width", 2);

  // Animate: grow from center
  arcs
    .transition()
    .duration(800)
    .attrTween("d", function (d) {
      const interpolate = (t: number) => {
        const arcInterp = d3Arc<any>()
          .innerRadius(innerRadius * t)
          .outerRadius(radius * t);
        return arcInterp(d)!;
      };
      return interpolate;
    });

  // Immediately set final state as fallback
  arcs.attr("d", arcGen);

  // Center label
  const centerLabel = svg
    .append("text")
    .attr("text-anchor", "middle")
    .attr("dominant-baseline", "central")
    .attr("font-size", 24)
    .attr("font-weight", "bold")
    .attr("fill", "currentColor");

  // Hover interaction
  arcs
    .on("pointerenter", function (_, d) {
      select(this).transition().duration(200).attr("opacity", 0.8);
      centerLabel.text(d.data.label);
    })
    .on("pointerleave", function () {
      select(this).transition().duration(200).attr("opacity", 1);
      centerLabel.text("");
    });

  return {
    update: (newData: SliceDatum[]) => {
      arcs
        .data(pieGen(newData))
        .transition()
        .duration(400)
        .attr("d", arcGen);
    },
    destroy: () => {
      select(container).select("svg").remove();
    },
  };
}
```

### Area Chart

```ts
import {
  select, scaleLinear, scaleUtc, axisBottom, axisLeft,
  area as d3Area, curveMonotoneX, extent,
} from "@/lib/d3";

function createAreaChart(
  container: HTMLElement,
  data: TimeSeriesDatum[],
  options?: ChartOptions
) {
  const { width, height, margin } = { ...defaults, ...options };
  const innerW = width - margin.left - margin.right;
  const innerH = height - margin.top - margin.bottom;

  select(container).select("svg").remove();

  const svg = select(container)
    .append("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("viewBox", `0 0 ${width} ${height}`)
    .attr("role", "img")
    .append("g")
    .attr("transform", `translate(${margin.left},${margin.top})`);

  const x = scaleUtc()
    .domain(extent(data, (d) => d.date) as [Date, Date])
    .range([0, innerW]);

  const y = scaleLinear()
    .domain([0, (extent(data, (d) => d.value)[1] ?? 0) * 1.1])
    .range([innerH, 0]);

  svg.append("g").attr("transform", `translate(0,${innerH})`).call(axisBottom(x).ticks(6));
  svg.append("g").call(axisLeft(y).ticks(5));

  const areaGen = d3Area<TimeSeriesDatum>()
    .x((d) => x(d.date))
    .y0(innerH)
    .y1((d) => y(d.value))
    .curve(curveMonotoneX);

  // Gradient fill
  const gradId = `area-grad-${Math.random().toString(36).slice(2, 8)}`;
  svg
    .append("defs")
    .append("linearGradient")
    .attr("id", gradId)
    .attr("gradientTransform", "rotate(90)")
    .selectAll("stop")
    .data([
      { offset: "0%", opacity: 0.4 },
      { offset: "100%", opacity: 0 },
    ])
    .join("stop")
    .attr("offset", (d) => d.offset)
    .attr("stop-color", "currentColor")
    .attr("stop-opacity", (d) => d.opacity);

  // Clip-path reveal animation
  const clipId = `area-clip-${Math.random().toString(36).slice(2, 8)}`;
  const clip = svg
    .append("defs")
    .append("clipPath")
    .attr("id", clipId)
    .append("rect")
    .attr("width", 0)
    .attr("height", innerH);

  svg
    .append("path")
    .datum(data)
    .attr("fill", `url(#${gradId})`)
    .attr("d", areaGen)
    .attr("clip-path", `url(#${clipId})`);

  svg
    .append("path")
    .datum(data)
    .attr("fill", "none")
    .attr("stroke", "currentColor")
    .attr("stroke-width", 2)
    .attr("d", areaGen)
    .attr("clip-path", `url(#${clipId})`);

  // Animate clip-path to reveal
  clip.transition().duration(1000).attr("width", innerW);

  return {
    update: () => {},
    destroy: () => {
      select(container).select("svg").remove();
    },
  };
}
```

## Interactive Patterns

### Tooltip (HTML overlay)

```ts
function addTooltip(container: HTMLElement) {
  const tooltip = document.createElement("div");
  Object.assign(tooltip.style, {
    position: "absolute",
    pointerEvents: "none",
    padding: "6px 10px",
    background: "var(--tooltip-bg, rgba(0,0,0,0.85))",
    color: "var(--tooltip-fg, white)",
    borderRadius: "4px",
    fontSize: "13px",
    opacity: "0",
    transition: "opacity 150ms",
    whiteSpace: "nowrap",
    zIndex: "10",
  });
  container.style.position = "relative";
  container.appendChild(tooltip);

  return {
    show(event: PointerEvent, text: string) {
      tooltip.textContent = text;
      tooltip.style.opacity = "1";
      const rect = container.getBoundingClientRect();
      tooltip.style.left = `${event.clientX - rect.left + 12}px`;
      tooltip.style.top = `${event.clientY - rect.top - 28}px`;
    },
    hide() {
      tooltip.style.opacity = "0";
    },
    destroy() {
      tooltip.remove();
    },
  };
}
```

Usage with any chart:
```ts
const tip = addTooltip(container);

svg.selectAll(".bar")
  .on("pointerenter", (event, d) => tip.show(event, `${d.label}: ${d.value}`))
  .on("pointermove", (event, d) => tip.show(event, `${d.label}: ${d.value}`))
  .on("pointerleave", () => tip.hide());
```

### Zoom & Pan

```ts
import { zoom, zoomIdentity, select } from "@/lib/d3";

function addZoom(
  svg: d3.Selection<SVGSVGElement, unknown, null, undefined>,
  content: d3.Selection<SVGGElement, unknown, null, undefined>,
) {
  const zoomBehavior = zoom<SVGSVGElement, unknown>()
    .scaleExtent([0.5, 8])
    .on("zoom", (event) => {
      content.attr("transform", event.transform);
    });

  svg.call(zoomBehavior);

  return {
    reset: () => svg.transition().duration(400).call(zoomBehavior.transform, zoomIdentity),
  };
}
```

### Brush Selection

```ts
import { brushX, select } from "@/lib/d3";

function addBrush(
  svg: d3.Selection<SVGGElement, unknown, null, undefined>,
  width: number,
  height: number,
  x: d3.ScaleTime<number, number>,
  onBrush: (range: [Date, Date]) => void
) {
  const brush = brushX<unknown>()
    .extent([[0, 0], [width, height]])
    .on("end", (event) => {
      if (!event.selection) return;
      const [x0, x1] = event.selection as [number, number];
      onBrush([x.invert(x0), x.invert(x1)]);
      // Clear brush after selection
      svg.select<SVGGElement>(".brush").call(brush.move, null);
    });

  svg.append("g").attr("class", "brush").call(brush);
}
```

## GSAP + D3 Integration

D3 owns data binding and SVG structure. GSAP owns scroll-triggered entrance. They complement each other — D3 doesn't have a ScrollTrigger equivalent, GSAP doesn't have scales/axes.

```ts
import { gsap, ScrollTrigger } from "@/lib/gsap";

function scrollTriggeredChart(
  container: HTMLElement,
  data: BarDatum[]
) {
  // 1. Build chart with D3 (bars start at height 0)
  const chart = createBarChart(container, data);

  // 2. GSAP controls the scroll reveal
  // D3 already animated bars on create — for scroll-triggered,
  // build bars without D3 transition, then use GSAP:
  const bars = container.querySelectorAll(".bar");

  gsap.from(bars, {
    scaleY: 0,
    transformOrigin: "bottom",
    stagger: 0.05,
    duration: 0.6,
    ease: "power3.out",
    scrollTrigger: {
      trigger: container,
      start: "top 75%",
      toggleActions: "play none none none",
    },
  });

  return chart;
}
```

## Framework Integration

### React

D3 manipulates the DOM directly via refs — same approach as GSAP in this skill. Keep D3 in `useEffect` (or `useGSAP` if combining with GSAP).

```tsx
import { useRef, useEffect } from "react";

export function BarChart({ data }: { data: BarDatum[] }) {
  const ref = useRef<HTMLDivElement>(null);
  const chartRef = useRef<ReturnType<typeof createBarChart>>();

  useEffect(() => {
    if (!ref.current) return;
    chartRef.current = createBarChart(ref.current, data);
    return () => chartRef.current?.destroy();
  }, []); // mount only

  useEffect(() => {
    chartRef.current?.update(data);
  }, [data]);

  return <div ref={ref} />;
}
```

### SolidJS

```tsx
import { onMount, onCleanup, createEffect } from "solid-js";

export function BarChart(props: { data: BarDatum[] }) {
  let container!: HTMLDivElement;
  let chart: ReturnType<typeof createBarChart>;

  onMount(() => {
    chart = createBarChart(container, props.data);
  });

  createEffect(() => {
    chart?.update(props.data);
  });

  onCleanup(() => chart?.destroy());

  return <div ref={container} />;
}
```

## Styling

D3 charts render as SVG — style with CSS, not inline attributes where possible:

```css
/* Chart base */
.bar { transition: opacity 150ms; }
.bar:hover { opacity: 0.8; }

/* Axes */
.x-axis text,
.y-axis text {
  font-size: 12px;
  fill: var(--chart-text, currentColor);
}

.x-axis line,
.x-axis path,
.y-axis line,
.y-axis path {
  stroke: var(--chart-grid, #e5e7eb);
}

/* Remove axis domain line for cleaner look */
.y-axis .domain { display: none; }

/* Grid lines */
.y-axis .tick line {
  stroke: var(--chart-grid, #e5e7eb);
  stroke-dasharray: 2 2;
}

/* Reduced motion */
@media (prefers-reduced-motion: reduce) {
  .bar, path, circle {
    transition: none !important;
  }
}
```

## Accessibility

```ts
// Add role="img" + aria-label to every chart SVG (shown in patterns above)

// For interactive charts, add a visually-hidden data table as fallback:
function addA11yTable(container: HTMLElement, data: BarDatum[]) {
  const table = document.createElement("table");
  table.className = "sr-only"; // Tailwind: screen-reader only

  const caption = document.createElement("caption");
  caption.textContent = "Chart data";
  table.appendChild(caption);

  const thead = document.createElement("thead");
  const headerRow = document.createElement("tr");
  for (const text of ["Label", "Value"]) {
    const th = document.createElement("th");
    th.textContent = text;
    headerRow.appendChild(th);
  }
  thead.appendChild(headerRow);
  table.appendChild(thead);

  const tbody = document.createElement("tbody");
  for (const d of data) {
    const tr = document.createElement("tr");
    const tdLabel = document.createElement("td");
    tdLabel.textContent = d.label;
    const tdValue = document.createElement("td");
    tdValue.textContent = String(d.value);
    tr.appendChild(tdLabel);
    tr.appendChild(tdValue);
    tbody.appendChild(tr);
  }
  table.appendChild(tbody);

  container.appendChild(table);
}
```
