# EV-Charging-Impact-on-a-Low-Voltage-Distribution-Feeder

> **EEE 4416: Simulation Lab**  
> **Islamic University of Technology (IUT)** — Department of Electrical & Electronic Engineering  
> **Author:** Nadman Ibne Mamun 
 

---

## Project Overview

This project provides an interactive MATLAB GUI application and simulation study evaluating the technical impacts of residential Electric Vehicle (EV) charging on a radial Low Voltage (LV) distribution network. 

The study models and quantitatively compares two distinct EV charging strategies:
1. **Uncoordinated Charging:** EVs begin charging simultaneously during the evening peak demand window (18:00).
2. **Coordinated (Staggered) Charging:** EV charging start times are distributed across the overnight off-peak period (starting at 22:00 with a 2-hour stagger interval).

Using a single-phase resistive radial voltage drop model and transformer loading calculations, the application demonstrates that network stress caused by EV adoption is primarily a **scheduling problem** rather than an infrastructure capacity limitation.

---

## Key Simulation Findings

Based on a representative test scenario of **5 houses (3 EV owners)** supplied by a **25 kVA Transformer** at **230V**:

* **Statutory Voltage Violation Resolved:** Uncoordinated charging depresses the end-of-feeder voltage to **216.5 V** (a **5.87% drop**), violating the typical 5% statutory voltage tolerance limit (218.5 V). Coordinated charging limits the worst-case drop to **3.40%** (222.2 V), remaining strictly within statutory limits all day.
* **Peak Transformer Loading Reduced:** Coordinated charging lowers peak transformer demand from **69.6%** down to **36.9%** without reducing energy delivery.
* **Identical Energy Served:** Both strategies successfully deliver the exact same daily energy demand (**143.6 kWh**).

---

## Performance Comparison

| Parameter | Uncoordinated | Coordinated | Impact / Improvement |
| :--- | :---: | :---: | :---: |
| **Connected EVs / Houses** | 3 / 5 | 3 / 5 | 60% EV Penetration |
| **Peak Transformer Loading** | 69.6% | 36.9% | **32.7% Reduction** |
| **Transformer Overloaded (>100%)?** | No | No | Operating within limits |
| **Min. Voltage at Last House** | 216.5 V | 222.2 V | **+5.7 V Increase** |
| **Max Voltage Drop** | 5.87% | 3.40% | **2.47% Improvement** |
| **Statutory Voltage Status (5%)** | ❌ **VIOLATION** | ✅ **PASSED** | Violation Resolved |
| **Total Daily Energy Delivered** | 143.6 kWh | 143.6 kWh | **100% Identical** |

---

##  MATLAB Application Features

The interactive MATLAB app (`EV_Grid_Impact_App.m`) is built programmatically using `uifigure` and organized into four core tabs:

1. **Tab 1 — Overview:** Core physics, governing equations, and setup instructions.
2. **Tab 2 — System Setup:** Fully customizable parameters (house count, EV penetration, transformer kVA, line resistance, and charging schedules) with a dynamic single-line diagram.
3. **Tab 3 — Simulation:** Interactive plots for 24-hour transformer loading, end-of-feeder voltage, worst-case bar charts, voltage profiles along the feeder, and a 24-hour peak animation feature.
4. **Tab 4 — Results:** Numerical comparative analysis, automated engineering interpretation text, and CSV data export capabilities.

---

##  How to Run the Application

1. Clone or download this repository.
2. Open **MATLAB** and set the working directory to the repository folder.
3. In the MATLAB Command Window, run:
   ```matlab
   EV_Grid_Impact_App
