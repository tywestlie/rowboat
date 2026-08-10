import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"

const BACKGROUND = "#0B1220"
const GRID_LINE = "#24314a"
const MUTED = "#8793aa"
const AMBER = [255, 179, 0]

const MARGIN = { top: 20, right: 24, bottom: 44, left: 60 }
const MIN_RADIUS = 2
const MAX_RADIUS = 8
const HIT_RADIUS = 12
const RESIZE_DEBOUNCE_MS = 150
const LOG_SCALE_MIN = 1
const POINT_BASE_ALPHA_MIN = 0.15
const POINT_BASE_ALPHA_MAX = 0.3

export default class extends Controller {
  static targets = ["canvas", "tooltip"]
  static values = { points: Array, datasetId: Number }

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

    const clampForLog = (value) => Math.max(value, LOG_SCALE_MIN)

    const xScale = d3.scaleLog()
      .domain(d3.extent(points, (d) => clampForLog(d.sy_dist)))
      .range([MARGIN.left, MARGIN.left + innerWidth])
      .clamp(true)
      .nice()

    const yScale = d3.scaleLog()
      .domain(d3.extent(points, (d) => clampForLog(d.pl_eqt)))
      .range([MARGIN.top + innerHeight, MARGIN.top])
      .clamp(true)
      .nice()

    const radiusScale = d3.scaleSqrt()
      .domain(d3.extent(points, (d) => d.pl_rade))
      .range([MIN_RADIUS, MAX_RADIUS])
      .clamp(true)

    const opacityScale = d3.scaleLinear()
      .domain(d3.extent(points, (d) => clampForLog(d.pl_eqt)))
      .range([POINT_BASE_ALPHA_MIN, POINT_BASE_ALPHA_MAX])
      .clamp(true)

    this.plotted = points.map((point) => ({
      ...point,
      x: xScale(clampForLog(point.sy_dist)),
      y: yScale(clampForLog(point.pl_eqt)),
      r: radiusScale(point.pl_rade),
      opacity: opacityScale(point.pl_eqt)
    }))

    this.drawAxes(ctx, xScale, yScale, innerWidth, innerHeight)

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

  drawAxes(ctx, xScale, yScale, innerWidth, innerHeight) {
    const format = d3.format("~s")

    ctx.lineWidth = 0.5
    ctx.font = "10px monospace"
    ctx.fillStyle = MUTED

    ctx.textAlign = "center"
    ctx.textBaseline = "top"
    for (const tick of xScale.ticks(6)) {
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
    for (const tick of yScale.ticks(6)) {
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
      "Distance from Earth (parsecs)",
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
    const layers = [
      { scale: 2.4, alpha: 0.12 * point.opacity },
      { scale: 1.5, alpha: 0.25 * point.opacity },
      { scale: 1, alpha: point.opacity }
    ]

    for (const layer of layers) {
      ctx.beginPath()
      ctx.fillStyle = `rgba(${AMBER[0]}, ${AMBER[1]}, ${AMBER[2]}, ${layer.alpha})`
      ctx.arc(point.x, point.y, point.r * layer.scale, 0, Math.PI * 2)
      ctx.fill()
    }
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

    const url = `/datasets/${this.datasetIdValue}/rows/${point.id}`

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
      [`Distance: ${point.sy_dist.toFixed(1)} pc`, "text-muted"],
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
