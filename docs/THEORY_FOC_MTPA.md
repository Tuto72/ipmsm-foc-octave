# Theory Behind GUI 2: Basic FOC and MTPA

This document summarizes the theory implemented in GUI 2. The simulation represents a PMSM/IPMSM drive using Field-Oriented Control (FOC), an averaged inverter, fixed-step numerical integration, and an optional Maximum Torque per Ampere (MTPA) current-reference block.

## 1. Modeling assumptions

The simulation uses the following assumptions:

- The motor is represented in the rotating d-q reference frame.
- The rotor electrical position is known.
- The back EMF is sinusoidal.
- Magnetic saturation, iron losses, and high-frequency PWM ripple are neglected.
- The inverter is modeled as an averaged d-q voltage source.
- The available voltage is limited by the DC-link voltage.
- Euler is the default numerical solver.
- RK4 is available as an optional fixed-step solver.

The goal is to study the closed-loop control behavior, not transistor-level switching phenomena.

## 2. Electrical model in the d-q reference frame

The stator voltage equations are:

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

The electrical and mechanical speeds are related by:

$$
\omega_e = p \omega_m
$$

where `p` is the number of pole pairs.

## 3. Electromagnetic torque

The electromagnetic torque is modeled as:

$$
T_e = \frac{3}{2}p\left[\psi_f i_q + (L_d - L_q)i_d i_q\right]
$$

The first term is the magnet torque contribution:

$$
T_{\text{pm}} = \frac{3}{2}p\psi_f i_q
$$

The second term is the reluctance torque contribution:

$$
T_{\text{rel}} = \frac{3}{2}p(L_d - L_q)i_d i_q
$$

For a typical IPMSM with `Lq > Ld`, a negative `id` and a positive `iq` produce positive reluctance torque, improving the torque per ampere.

## 4. Mechanical model

The mechanical equation is:

$$
J\frac{d\omega_m}{dt} = T_e - T_L - B\omega_m
$$

Solving for the speed derivative:

$$
\frac{d\omega_m}{dt} = \frac{T_e - T_L - B\omega_m}{J}
$$

where:

- `J` is the inertia.
- `B` is the viscous friction coefficient.
- `T_L` is the load torque.

## 5. State vector

The closed-loop state vector used by the simulation is:

$$
x =
\begin{bmatrix}
i_d \\
i_q \\
\omega_m \\
\xi_d \\
\xi_q \\
\xi_\omega
\end{bmatrix}
$$

where:

- `id`, `iq` are the motor currents.
- `wm` is the mechanical speed.
- `xi_d`, `xi_q` are the current-controller integral states.
- `xi_w` is the speed-controller integral state.

## 6. Speed controller

The outer speed controller receives the speed error:

$$
e_\omega = \omega_m^* - \omega_m
$$

The PI speed controller produces a signed stator-current magnitude command:

$$
I_{s,\text{unsat}}^* = K_{p\omega}e_\omega + \xi_\omega
$$

This value is limited by the maximum stator current:

$$
I_s^* = \text{sat}(I_{s,\text{unsat}}^*, -I_{\max}, I_{\max})
$$

The speed-controller integrator follows:

$$
\frac{d\xi_\omega}{dt} = K_{i\omega}e_\omega
$$

The code applies conditional integration anti-windup. If the controller output is saturated and the integrator would push it farther into saturation, the integrator derivative is set to zero.

## 7. Basic FOC current references

In Basic FOC mode, the direct-axis reference is fixed to zero:

$$
i_d^* = 0
$$

The q-axis current reference equals the signed current command from the speed controller:

$$
i_q^* = I_s^*
$$

This strategy makes the q-axis current the torque-producing current. It is especially useful as a baseline and for non-salient PMSM operation.

## 8. MTPA current references

MTPA means **Maximum Torque per Ampere**. The goal is to generate the required torque with the smallest stator-current magnitude:

$$
I_s = \sqrt{i_d^2 + i_q^2}
$$

For a salient IPMSM, the reluctance torque allows part of the torque production to come from a negative direct-axis current. The current constraint is:

$$
(I_{s}^{*})^2 = (i_{d}^{*})^2 + (i_{q}^{*})^2
$$

For `Lq > Ld`, the implemented MTPA expression is:

$$
i_d^* = \frac{\psi_f - \sqrt{\psi_f^2 + 8(L_q - L_d)^2(I_s^*)^2}}{4(L_q - L_d)}
$$

The q-axis current reference is then obtained from the current circle:

$$
i_q^* = \text{sign}(I_s^*)\sqrt{(I_s^*)^2 - (i_d^*)^2}
$$

If `Is* = 0`, the references are:

$$
i_d^* = 0, \qquad i_q^* = 0
$$

If `Lq <= Ld`, the GUI falls back to Basic FOC:

$$
i_d^* = 0, \qquad i_q^* = I_s^*
$$

This fallback avoids applying an IPMSM MTPA formula to a non-salient or differently salient machine.

## 9. Current controllers

The current errors are:

$$
e_d = i_d^* - i_d
$$

$$
e_q = i_q^* - i_q
$$

The PI current-controller outputs are:

$$
v_{d,\text{PI}} = K_{pd}e_d + \xi_d
$$

$$
v_{q,\text{PI}} = K_{pq}e_q + \xi_q
$$

with integral-state dynamics:

$$
\frac{d\xi_d}{dt} = K_{id}e_d
$$

$$
\frac{d\xi_q}{dt} = K_{iq}e_q
$$

Conditional integration anti-windup is applied to the current-controller integrators.

## 10. Decoupling feedforward

The PMSM voltage equations contain cross-coupling terms. The GUI adds feedforward compensation:

$$
v_{d,\text{cmd}} = v_{d,\text{PI}} - \omega_e L_q i_q
$$

$$
v_{q,\text{cmd}} = v_{q,\text{PI}} + \omega_e(L_d i_d + \psi_f)
$$

These terms help the PI controllers track the current references more directly by compensating speed-dependent coupling.

## 11. Averaged inverter voltage limit

The GUI does not simulate PWM switching. It uses an averaged inverter model with maximum voltage:

$$
V_{\max} = \frac{V_{dc}}{\sqrt{3}}
$$

The requested voltage magnitude is:

$$
V_s = \sqrt{v_{d,\text{cmd}}^2 + v_{q,\text{cmd}}^2}
$$

If `Vs <= Vmax`, the commanded voltages are applied directly:

$$
v_d = v_{d,\text{cmd}}, \qquad v_q = v_{q,\text{cmd}}
$$

If `Vs > Vmax`, radial voltage limitation is applied:

$$
v_d = \frac{V_{\max}}{V_s}v_{d,\text{cmd}}
$$

$$
v_q = \frac{V_{\max}}{V_s}v_{q,\text{cmd}}
$$

The GUI stores a voltage saturation flag when this condition occurs.

## 12. Euler solver

Euler is the default solver. For the state equation:

$$
\dot{x} = f(t, x)
$$

Euler updates the state as:

$$
x_{k+1} = x_k + h f(t_k, x_k)
$$

where `h = dt`. Euler is simple and transparent, which makes it suitable for an educational GUI and for fixed-step control simulations.

## 13. RK4 optional solver

RK4 is available for comparison:

$$
\begin{aligned}
k_1 &= f(t_k, x_k) \\
k_2 &= f(t_k + h/2, x_k + hk_1/2) \\
k_3 &= f(t_k + h/2, x_k + hk_2/2) \\
k_4 &= f(t_k + h, x_k + hk_3) \\
x_{k+1} &= x_k + \frac{h}{6}(k_1 + 2k_2 + 2k_3 + k_4)
\end{aligned}
$$

RK4 is more accurate for the same step size, but it requires more computation.

## 14. Stored results

The GUI stores the following main time-domain signals:

- `t`: time.
- `id`, `iq`: measured d-axis and q-axis currents.
- `id_ref`, `iq_ref`: current references.
- `Is`: stator-current magnitude.
- `Is_ref`: current-magnitude reference.
- `wm`: mechanical speed.
- `wref`: speed reference.
- `Te`: electromagnetic torque.
- `Tref`: torque associated with current references.
- `Tload`: load torque.
- `vd`, `vq`: applied d-axis and q-axis voltages.
- `Vs`: voltage magnitude.
- `Vmax`: inverter voltage limit.
- `sat_v`: voltage saturation flag.
- `sat_i`: current saturation flag.

## 15. Interpretation of the dq current plot

The GUI displays:

- `id*`: direct-axis current reference.
- `id`: direct-axis current.
- `iq*`: quadrature-axis current reference.
- `iq`: quadrature-axis current.
- `Is`: stator-current magnitude.

This makes the difference between Basic FOC and FOC + MTPA visible. In MTPA mode, the direct-axis reference normally becomes negative for a salient IPMSM, while the current magnitude remains limited by `Imax`.

## 16. Current version limitations

The current GUI focuses on Basic FOC and MTPA. It does not yet include:

- Flux weakening.
- MTPV.
- Voltage ellipse/current circle operation maps.
- Magnetic saturation.
- Iron losses.
- PWM switching ripple.
- Sensorless position estimation.

These topics can be added in future GUI versions.
