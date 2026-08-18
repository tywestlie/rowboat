import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"

const BACKGROUND = "#0B1220"
const GRID_LINE = "#24314a"
const MUTED = "#8793aa"
const AMBER = [255, 179, 0]

const MARGIN = { top: 20, right: 24, bottom: 44, left: 60 }
const MIN_RADIUS = 1
const MAX_RADIUS = 5
const HIT_RADIUS = 12
const RESIZE_DEBOUNCE_MS = 150
const LOG_SCALE_MIN = 1

// The dense overview (thousands of overlapping points) relies on additive
// blending to build up brightness, so individual points are drawn faint.
// A single system (a handful of points, no overlap) needs the opposite:
// bold, fully-opaque points, or they're nearly invisible. Interpolate
// between these two alpha ranges based on how many points are on screen.
const DENSE_ALPHA_MIN = 0.1
const DENSE_ALPHA_MAX = 0.22
const SPARSE_ALPHA_MIN = 0.85
const SPARSE_ALPHA_MAX = 1
const SPARSE_POINT_COUNT = 30
const DENSE_POINT_COUNT = 500

const GLOW_RADIUS_MULTIPLIER = 1.8
const GLOW_CORE_STOP = 0.4

const generateLogTicks = (scale) => {
  const [min, max] = scale.domain()
  const startExp = Math.floor(Math.log10(min))
  const endExp = Math.ceil(Math.log10(max))
  const candidates = []

  for (let exp = startExp; exp <= endExp; exp++) {
    const base = 10 ** exp
    candidates.push(base, base * 5)
  }

  return candidates.filter((value) => value >= min && value <= max)
}

export default class extends Controller {
  static targets = ["canvas", "tooltip"]
  static values = { points: Array, mode: String }

  connect() {
    this.plotted = []
    this.quadtree = null

    this.handleMouseMove = this.handleMouseMove.bind(this)
    this.handleMouseLeave = this.handleMouseLeave.bind(this)
    this.handleClick = this.handleClick.bind(this)

    this.canvasTarget.addEventListener("mousemove", this.handleMouseMove)
    this.canvasTarget.addEventListener("mouseleave", this.handleMouseLeave)
    this.canvasTarget.addEventListener("click", this.handleClick)

    this.resizeObserver = new ResizeObserver(() => this.scheduleRender())
    this.resizeObserver.observe(this.element)

    this.render()
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    clearTimeout(this.resizeTimeout)

    this.canvasTarget.removeEventListener("mousemove", this.handleMouseMove)
    this.canvasTarget.removeEventListener("mouseleave", this.handleMouseLeave)
    this.canvasTarget.removeEventListener("click", this.handleClick)
  }

  scheduleRender() {
    clearTimeout(this.resizeTimeout)
    this.resizeTimeout = setTimeout(() => this.render(), RESIZE_DEBOUNCE_MS)
  }

  render() {
    const points = this.pointsValue
    const canvas = this.canvasTarget
    const rect = this.element.getBoundingClientRect()
    const width = Math.max(Math.round(rect.width), 320)
    const height = Math.round(width * 0.55)
    const dpr = window.devicePixelRatio || 1

    canvas.style.width = `${width}px`
    canvas.style.height = `${height}px`
    canvas.width = width * dpr
    canvas.height = height * dpr

    const ctx = canvas.getContext("2d")
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    ctx.fillStyle = BACKGROUND
    ctx.fillRect(0, 0, width, height)

    this.plotted = []
    this.quadtree = null

    if (points.length === 0) return

    const innerWidth = width - MARGIN.left - MARGIN.right
    const innerHeight = height - MARGIN.top - MARGIN.bottom

    // "system" mode (a single host star filtered in) plots orbital period
    // instead of distance from Earth, which is identical for every planet
    // in the same system and would collapse to a single x position. Values
    // within one system also span a much smaller range, so linear scales
    // read better here than the log scales used for the full-sky view.
    const isSystemMode = this.modeValue === "system"
    const xField = isSystemMode ? "pl_orbper" : "sy_dist"
    const xLabel = isSystemMode ? "Orbital period (days)" : "Distance from Earth (parsecs)"
    const clampForLog = (value) => Math.max(value, LOG_SCALE_MIN)

    const xScale = isSystemMode
      ? d3.scaleLinear()
        .domain(d3.extent(points, (d) => d[xField]))
        .range([MARGIN.left, MARGIN.left + innerWidth])
        .clamp(true)
        .nice()
      : d3.scaleLog()
        .domain(d3.extent(points, (d) => clampForLog(d[xField])))
        .range([MARGIN.left, MARGIN.left + innerWidth])
        .clamp(true)
        .nice()

    const yScale = isSystemMode
      ? d3.scaleLinear()
        .domain(d3.extent(points, (d) => d.pl_eqt))
        .range([MARGIN.top + innerHeight, MARGIN.top])
        .clamp(true)
        .nice()
      : d3.scaleLog()
        .domain(d3.extent(points, (d) => clampForLog(d.pl_eqt)))
        .range([MARGIN.top + innerHeight, MARGIN.top])
        .clamp(true)
        .nice()

    const radiusScale = d3.scaleSqrt()
      .domain(d3.extent(points, (d) => d.pl_rade))
      .range([MIN_RADIUS, MAX_RADIUS])
      .clamp(true)

    const sparseness = d3.scaleLinear()
      .domain([SPARSE_POINT_COUNT, DENSE_POINT_COUNT])
      .range([1, 0])
      .clamp(true)(points.length)

    const alphaMin = d3.interpolateNumber(DENSE_ALPHA_MIN, SPARSE_ALPHA_MIN)(sparseness)
    const alphaMax = d3.interpolateNumber(DENSE_ALPHA_MAX, SPARSE_ALPHA_MAX)(sparseness)

    const opacityScale = d3.scaleLinear()
      .domain(d3.extent(points, (d) => (isSystemMode ? d.pl_eqt : clampForLog(d.pl_eqt))))
      .range([alphaMin, alphaMax])
      .clamp(true)

    this.plotted = points.map((point) => ({
      ...point,
      x: xScale(isSystemMode ? point[xField] : clampForLog(point[xField])),
      y: yScale(isSystemMode ? point.pl_eqt : clampForLog(point.pl_eqt)),
      r: radiusScale(point.pl_rade),
      opacity: opacityScale(point.pl_eqt)
    }))

    this.drawAxes(ctx, xScale, yScale, innerWidth, innerHeight, { isSystemMode, xLabel })

    ctx.globalCompositeOperation = "lighter"
    for (const point of this.plotted) {
      this.drawPoint(ctx, point)
    }
    ctx.globalCompositeOperation = "source-over"

    this.quadtree = d3.quadtree()
      .x((d) => d.x)
      .y((d) => d.y)
      .addAll(this.plotted)
  }

  drawAxes(ctx, xScale, yScale, innerWidth, innerHeight, { isSystemMode = false, xLabel = "Distance from Earth (parsecs)" } = {}) {
    const format = d3.format("~s")
    const xTicks = isSystemMode ? xScale.ticks(6) : generateLogTicks(xScale)
    const yTicks = isSystemMode ? yScale.ticks(6) : generateLogTicks(yScale)

    ctx.lineWidth = 0.5
    ctx.font = "10px monospace"
    ctx.fillStyle = MUTED

    ctx.textAlign = "center"
    ctx.textBaseline = "top"
    for (const tick of xTicks) {
      const x = xScale(tick)

      ctx.strokeStyle = GRID_LINE
      ctx.globalAlpha = 0.15
      ctx.beginPath()
      ctx.moveTo(x, MARGIN.top)
      ctx.lineTo(x, MARGIN.top + innerHeight)
      ctx.stroke()

      ctx.globalAlpha = 0.6
      ctx.fillText(format(tick), x, MARGIN.top + innerHeight + 6)
    }

    ctx.textAlign = "right"
    ctx.textBaseline = "middle"
    for (const tick of yTicks) {
      const y = yScale(tick)

      ctx.strokeStyle = GRID_LINE
      ctx.globalAlpha = 0.08
      ctx.beginPath()
      ctx.moveTo(MARGIN.left, y)
      ctx.lineTo(MARGIN.left + innerWidth, y)
      ctx.stroke()

      ctx.globalAlpha = 0.6
      ctx.fillText(format(tick), MARGIN.left - 8, y)
    }

    ctx.globalAlpha = 0.6
    ctx.textAlign = "center"
    ctx.textBaseline = "alphabetic"
    ctx.fillText(
      xLabel,
      MARGIN.left + innerWidth / 2,
      MARGIN.top + innerHeight + 34
    )

    ctx.save()
    ctx.translate(16, MARGIN.top + innerHeight / 2)
    ctx.rotate(-Math.PI / 2)
    ctx.textAlign = "center"
    ctx.fillText("Equilibrium temperature (K)", 0, 0)
    ctx.restore()

    ctx.globalAlpha = 1
  }

  drawPoint(ctx, point) {
    const glowRadius = point.r * GLOW_RADIUS_MULTIPLIER
    const gradient = ctx.createRadialGradient(point.x, point.y, 0, point.x, point.y, glowRadius)

    gradient.addColorStop(0, `rgba(${AMBER[0]}, ${AMBER[1]}, ${AMBER[2]}, ${point.opacity})`)
    gradient.addColorStop(GLOW_CORE_STOP, `rgba(${AMBER[0]}, ${AMBER[1]}, ${AMBER[2]}, ${point.opacity})`)
    gradient.addColorStop(1, `rgba(${AMBER[0]}, ${AMBER[1]}, ${AMBER[2]}, 0)`)

    ctx.beginPath()
    ctx.fillStyle = gradient
    ctx.arc(point.x, point.y, glowRadius, 0, Math.PI * 2)
    ctx.fill()
  }

  findNearest(x, y) {
    if (!this.quadtree) return null

    return this.quadtree.find(x, y, HIT_RADIUS) || null
  }

  handleMouseMove(event) {
    const rect = this.canvasTarget.getBoundingClientRect()
    const point = this.findNearest(event.clientX - rect.left, event.clientY - rect.top)

    if (point) {
      this.canvasTarget.style.cursor = "pointer"
      this.showTooltip(point, event.clientX, event.clientY)
    } else {
      this.canvasTarget.style.cursor = "default"
      this.hideTooltip()
    }
  }

  handleMouseLeave() {
    this.canvasTarget.style.cursor = "default"
    this.hideTooltip()
  }

  handleClick(event) {
    const rect = this.canvasTarget.getBoundingClientRect()
    const point = this.findNearest(event.clientX - rect.left, event.clientY - rect.top)

    if (!point) return

    const url = `/exoplanets/${point.id}`

    if (window.Turbo) {
      window.Turbo.visit(url)
    } else {
      window.location.href = url
    }
  }

  showTooltip(point, clientX, clientY) {
    const tooltip = this.tooltipTarget
    tooltip.replaceChildren()

    const rows = [
      [point.pl_name || "Unknown planet", "font-medium text-signal"],
      this.modeValue === "system" && point.pl_orbper != null
        ? [`Orbital period: ${point.pl_orbper.toFixed(1)} days`, "text-muted"]
        : [`Distance: ${point.sy_dist.toFixed(1)} pc`, "text-muted"],
      [`Temp: ${Math.round(point.pl_eqt)} K`, "text-muted"],
      [`Radius: ${point.pl_rade.toFixed(2)} R⊕`, "text-muted"]
    ]

    for (const [text, className] of rows) {
      const line = document.createElement("div")
      line.className = className
      line.textContent = text
      tooltip.appendChild(line)
    }

    tooltip.style.left = `${clientX + 14}px`
    tooltip.style.top = `${clientY + 14}px`
    tooltip.classList.remove("hidden")
  }

  hideTooltip() {
    this.tooltipTarget.classList.add("hidden")
  }
}
