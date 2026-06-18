# Theory Behind FOC-GUI: Basic Field-Oriented Control

## 1. Scope

FOC-GUI simulates a PMSM/IPMSM drive using a control-oriented averaged model. The inverter does not switch. Instead, it applies the commanded `dq` voltage vector after a magnitude limitation derived from the DC-link voltage.

The baseline controller implements basic Field-Oriented Control (FOC):

$$
i_d^* = 0
$$

The `q`-axis current command comes from the speed PI controller through a torque reference.

The default numerical solver in the FOC-GUI is fixed-step **Euler**. A fixed-step **RK4** option is also available from the solver selector for comparison.

## 2. Electrical model in the dq frame

The PMSM/IPMSM voltage equations used in the simulation are:

$$
v_d = R_s i_d + L_d \frac{di_d}{dt} - \omega_e L_q i_q
$$

$$
v_q = R_s i_q + L_q \frac{di_q}{dt} + \omega_e (L_d i_d + \psi_f)
$$

Solving for the current derivatives gives:

$$
\frac{di_d}{dt} = \frac{v_d - R_s i_d + \omega_e L_q i_q}{L_d}
$$

$$
\frac{di_q}{dt} = \frac{v_q - R_s i_q - \omega_e (L_d i_d + \psi_f)}{L_q}
$$

The electrical speed is computed from the mechanical speed as:

$$
\omega_e = p \omega_m
$$

where `p` is the number of pole pairs.

## 3. Electromagnetic torque

The IPMSM torque equation is:

$$
T_e = \frac{3}{2} p \left[\psi_f i_q + (L_d - L_q)i_d i_q\right]
$$

In FOC-GUI, the reference strategy fixes `id_ref = 0`. Under that condition, the torque equation becomes approximately linear in `iq`:

$$
T_e \approx \frac{3}{2} p \psi_f i_q
$$

Therefore, the torque constant used for the basic current reference is:

$$
K_t = \frac{3}{2} p \psi_f
$$

and

$$
i_q^* = \frac{T^*}{K_t}
$$

The current reference is limited by the maximum current:

$$
-I_{\max} \leq i_q^* \leq I_{\max}
$$

## 4. Mechanical model

The mechanical equation is:

$$
J \frac{d\omega_m}{dt} = T_e - T_L - B\omega_m
$$

or

$$
\frac{d\omega_m}{dt} = \frac{T_e - T_L - B\omega_m}{J}
$$

## 5. Speed controller

The speed error is:

$$
e_\omega = \omega_m^* - \omega_m
$$

The speed PI controller produces the torque reference:

$$
T^* = K_{p\omega} e_\omega + \xi_\omega
$$

with integrator state:

$$
\frac{d\xi_\omega}{dt} = K_{i\omega} e_\omega
$$

The torque command is limited by the current limit using the `id = 0` torque constant:

$$
T_{\max} = K_t I_{\max}
$$

Therefore:

$$
-T_{\max} \leq T^* \leq T_{\max}
$$

## 6. Current controllers

The current errors are:

$$
e_d = i_d^* - i_d
$$

$$
e_q = i_q^* - i_q
$$

The PI outputs are:

$$
v_{d,PI} = K_{pd} e_d + \xi_d
$$

$$
v_{q,PI} = K_{pq} e_q + \xi_q
$$

with integrator states:

$$
\frac{d\xi_d}{dt} = K_{id} e_d
$$

$$
\frac{d\xi_q}{dt} = K_{iq} e_q
$$

## 7. Anti-windup logic

FOC-GUI uses a simple conditional-integration anti-windup rule. If a PI output is beyond its saturation limit and the integrator would push it farther into saturation, the integrator derivative is set to zero.

For a generic PI output `u_unsat` with limits `umin` and `umax`, the implemented logic is:

```text
if u_unsat >= umax and dxi_raw > 0: dxi = 0
if u_unsat <= umin and dxi_raw < 0: dxi = 0
otherwise: dxi = dxi_raw
```

This rule is applied to the speed PI and to the two current PIs.

## 8. Feedforward decoupling

The model contains speed-dependent cross-coupling terms. FOC-GUI compensates them with feedforward terms:

$$
v_d^* = v_{d,PI} - \omega_e L_q i_q
$$

$$
v_q^* = v_{q,PI} + \omega_e (L_d i_d + \psi_f)
$$

This improves current tracking, especially as speed increases.

## 9. Averaged inverter and voltage limitation

The inverter is represented as a voltage vector limiter. The available voltage magnitude is approximated as:

$$
V_{\max} = \frac{V_{dc}}{\sqrt{3}}
$$

The commanded voltage magnitude is:

$$
V_s = \sqrt{v_d^{*2} + v_q^{*2}}
$$

If `Vs > Vmax`, the command is scaled radially:

$$
v_d = v_d^* \frac{V_{\max}}{V_s}
$$

$$
v_q = v_q^* \frac{V_{\max}}{V_s}
$$

Otherwise:

$$
v_d = v_d^* , \qquad v_q = v_q^*
$$

## 10. Closed-loop state vector

The solver integrates the following state vector:

$$
x = [i_d,\ i_q,\ \omega_m,\ \xi_d,\ \xi_q,\ \xi_\omega]^T
$$

The first three states belong to the physical motor model. The last three states belong to the PI controller integrators.

## 11. Default numerical integration: Euler

The default solver is fixed-step Euler. For the closed-loop differential equation

$$
\dot{x} = f(t, x)
$$

with step size `h = dt`, Euler updates the state as:

$$
x_{k+1} = x_k + h f(t_k, x_k)
$$

Euler is useful in FOC-GUI because it is simple, fast, deterministic, and easy to relate to a sampled-time control implementation. The accuracy depends strongly on the selected step size `dt`, so smaller values of `dt` generally improve the numerical result.

## 12. Optional numerical integration: RK4

RK4 is also available in the FOC-GUI for comparison. It evaluates the right-hand side four times per step:

$$
k_1 = f(t_k, x_k)
$$

$$
k_2 = f(t_k + h/2, x_k + h k_1/2)
$$

$$
k_3 = f(t_k + h/2, x_k + h k_2/2)
$$

$$
k_4 = f(t_k + h, x_k + h k_3)
$$

$$
x_{k+1} = x_k + \frac{h}{6}(k_1 + 2k_2 + 2k_3 + k_4)
$$

RK4 usually gives a more accurate result than Euler for the same step size, but it requires more computation per simulation step.

## 13. Quantities plotted and exported

The FOC-GUI plots and exports the main simulation signals:

- mechanical speed reference and mechanical speed;
- electromagnetic torque, load torque, and torque reference;
- `d`- and `q`-axis current references and actual currents;
- `d`- and `q`-axis voltages;
- voltage magnitude `Vs` and voltage limit `Vmax`;
- current magnitude `Is`;
- voltage and current saturation flags.

The MAT-file export stores:

```text
results
params
compute_time_s
```

The CSV export stores the time-series signals and creates an auxiliary MAT-file containing the parameters and computation time.
