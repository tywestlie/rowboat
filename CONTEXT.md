# Rowboat

An AI-powered data explorer for public astronomy datasets. Users import real data from public APIs, then ask natural-language questions and get back structured answers and visualizations.

## Language

**Star System**:
A group of `DatasetRow`s that share the same `hostname` value — one or more confirmed planets orbiting the same host star.
_Avoid_: "host", "star" (ambiguous between the star itself and the system as a whole)

**Multi-planet System**:
A star system with 2 or more confirmed planets. The systems list view defaults to showing only these, with an opt-in toggle (`?all=1`) to reveal single-planet systems too.
_Avoid_: "system" alone when the planet-count threshold matters — a single-planet system is still a star system, just not a multi-planet one.

**Host Star**:
The star a planet orbits, identified by the `hostname` field on a `DatasetRow`. Not a modeled entity of its own — it's implicit in the grouping, not a row or table.
_Avoid_: "system name" (a host star name identifies the star; the system is the group of planets around it)
