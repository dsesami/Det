# Det.v
Verilog module for calculating the [determinant of a tridiagonal matrix](https://en.wikipedia.org/wiki/Tridiagonal_matrix#Determinant) in hardware.

The module assumes a 10x10 tridiagonal matrix stored in SRAM, tightly packed. For example, the smaller 4x4 matrix:

[a1 b1 00 00]

[c1 a2 b2 00]

[00 c2 a3 b3]

[00 00 c3 a4]

Would be represented in SRAM as follows:

[a1 b1]

[a2 b2]

[c2 a3]

[b3 c3]

[a4 ..]

[.. ..]

With the determinant being written to the row of SRAM directly below the last non-zero value represented in the matrix.
