# Student Records and Exam Management — x86 Assembly

**University group project | Academic year 2024/2025 | University of Verona**

A command-line application written in **x86 Assembly (AT&T syntax)** for managing university students' exam records. The program reads and updates text files, calculates grade averages, displays exam statistics, and ranks students according to their academic results.

This project was developed by a **team of three students** for the *Digital Logic and Computer Architecture Laboratory* coursework. We implemented **all mandatory features specified for three-person teams**, including the additional student-ranking functionality.

> **Language:** The application, its console messages, input data, and original project report are in **Italian**. This README is in English for accessibility.

## Features

The executable supports two operating modes.

### 1. Interactive mode — student and exam queries

Run the program without arguments to open an interactive menu:

```bash
./bin/appelli
```

The menu provides four options:

1. **Exit** — close the application.
2. **View a student's academic record** — search by student ID (*matricola*) and display the student's name, completed exams, grades, credits, arithmetic mean, and credit-weighted mean.
3. **View exam results** — enter an exam code to display the average grade obtained by students who passed that exam.
4. **View student ranking** — list students in descending order of weighted average. If two students have the same average, the student with **more earned credits** ranks higher. This feature was mandatory for groups of three.

All averages are represented as integers and **rounded down**, as required by the assignment.

### 2. Import mode — update exam records

Provide the path to an exam-register file:

```bash
./bin/appelli data/registro_fisica.txt
```

The program reads the student registry and existing grade records, imports the exam results, checks that referenced students are registered, and updates `data/libretti.txt`. It reports errors or warnings when the input data is invalid or inconsistent.

**Important:** Import mode **modifies `data/libretti.txt`**. Back up the file before experimenting with new imports. Run the executable from the repository's root directory so that relative paths resolve correctly.

## Requirements

- A Linux environment compatible with the project's x86 Assembly toolchain (or a suitable Linux VM / WSL setup)
- GNU Make (`make`)
- The assembler and linker invoked by the included `Makefile`

## Build and Run

**1. Clone the repository**

```bash
git clone https://github.com/edy3991/x86-Assembly-Student-Grades.git
cd x86-Assembly-Student-Grades
```

**2. Build the application** from the project root:

```bash
make
```

The `Makefile` compiles the Assembly sources into object files under `obj/` and creates the executable **`bin/appelli`**.

If the build fails because the output directories are missing, create them and run `make` again:

```bash
mkdir -p bin obj
make
```

**3. Run one of the two modes:**

```bash
# Interactive menu
./bin/appelli

# Import an exam register
./bin/appelli data/registro_programmazione.txt
```

## Input Data

The `data/` directory contains the text files used by the program:

| File | Purpose |
| --- | --- |
| `anagrafica.txt` | Student IDs, first names, and last names |
| `libretti.txt` | Exams recorded for each student, including credits and grades |
| `registro_*.txt` | Exam registers to import, containing an exam code, credits, and student results |

The assignment specifies these input formats:

**Student registry (`anagrafica.txt`):**

```text
VR123456:Mario Rossi
```

**Academic records (`libretti.txt`):**

```text
VR123456 ABC:6:30;EFG:10:28
```

**Exam register (example):**

```text
ABC:6:2
VR123456:30
VR789012:18
```

## Repository Structure

```text
.
├── src/             # x86 Assembly source code (.s)
├── data/            # Student records and exam-register files
├── Makefile         # Build instructions
├── Relazione.pdf    # Original project report (Italian)
├── bin/             # Generated executable (not tracked)
└── obj/             # Generated object files (not tracked)
```

`bin/` and `obj/` may not be present immediately after cloning because generated build files are excluded from Git.

## Academic Context

This assignment was part of the **2024/2025** *Digital Logic and Computer Architecture Laboratory* at the **University of Verona**. It was completed collaboratively by **three students**, and therefore includes the full set of requirements for three-person groups, especially the ranking and tie-breaking rules.

The project demonstrates low-level programming in Assembly, file handling, student-record management, integer arithmetic, input validation, and modular organization across source files.

For additional implementation details and the original explanation of the team's work, see [Relazione.pdf](Relazione.pdf) (in Italian).
