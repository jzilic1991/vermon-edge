(lang dune 2.8)
(name monpoly)
(version 1.1.10)

(generate_opam_files true)

(license "LGPL-2.1-only WITH OCaml-LGPL-linking-exception")
(authors
  "Eugen Zalinescu <eugen.zalinescu@gmail.com>"
  "Matus Harvan <matus.harvan@inf.ethz.ch>"
  "Srđan Krstić <srdan.krstic@inf.ethz.ch>"
  "Joshua Schneider <joshua.schneider@inf.ethz.ch>"
  "Dmitriy Traytel <traytel@di.ku.dk>")
(maintainers
  "Joshua Schneider <joshua.schneider@inf.ethz.ch>"
  "Eugen Zalinescu <eugen.zalinescu@gmail.com>")
(source (uri "git+https://bitbucket.org/monpoly/monpoly.git"))
(homepage "https://infsec.ethz.ch/research/software/monpoly.html")
(bug_reports "https://bitbucket.org/monpoly/monpoly/issues")

(package
  (name monpoly)
  (synopsis "Check compliance of log files with respect to policies")
  (description "\
MonPoly is a prototype monitoring tool. It checks the compliance of log files
with respect to policies that are specified by formulas in Metric First-Order
Temporal Logic (MFOTL) with aggregations.")
  (depends
    (ocaml (= 4.11))))
