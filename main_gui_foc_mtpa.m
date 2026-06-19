function main_gui_foc_mtpa()
% IPMSM FOC Control Studio - GUI 2: Basic FOC and MTPA
% GitHub-ready version: English GUI, averaged inverter, Euler/RK4 solvers,
% MTPA current-reference generation, computation-time display, and result export.
%
% Run in GNU Octave with:
%   main_gui_foc_mtpa
%
% This model does NOT simulate high-frequency semiconductor switching.
% The inverter is represented as a dq voltage source limited by Vdc/sqrt(3).

  close all;
  params = default_params();

  h.fig = figure( ...
    "name", "IPMSM FOC Control Studio - GUI 2: Basic FOC and MTPA", ...
    "numbertitle", "off", ...
    "position", [60 50 1350 780]);

  h.panel_params = uipanel( ...
    "parent", h.fig, ...
    "title", "Parameters", ...
    "position", [0.02 0.37 0.36 0.58]);

  h.panel_actions = uipanel( ...
    "parent", h.fig, ...
    "title", "Actions", ...
    "position", [0.02 0.05 0.36 0.29]);

  h.panel_plots = uipanel( ...
    "parent", h.fig, ...
    "title", "Results", ...
    "position", [0.40 0.05 0.58 0.90]);

  % Column coordinates inside parameter panel.
  xL = 0.04;
  xR = 0.52;
  yL = 0.925;
  yR = 0.925;

  % Left column: motor, inverter, operation mode.
  add_section(h.panel_params, "IPMSM motor", xL, yL); yL = yL - 0.055;
  h.Rs   = add_edit(h.panel_params, "Rs [ohm]",        params.motor.Rs,   xL, yL); yL = yL - 0.055;
  h.Ld   = add_edit(h.panel_params, "Ld [H]",          params.motor.Ld,   xL, yL); yL = yL - 0.055;
  h.Lq   = add_edit(h.panel_params, "Lq [H]",          params.motor.Lq,   xL, yL); yL = yL - 0.055;
  h.psif = add_edit(h.panel_params, "psi_f [Wb]",      params.motor.psif, xL, yL); yL = yL - 0.055;
  h.p    = add_edit(h.panel_params, "Pole pairs",      params.motor.p,    xL, yL); yL = yL - 0.055;
  h.J    = add_edit(h.panel_params, "J [kg m^2]",      params.motor.J,    xL, yL); yL = yL - 0.055;
  h.B    = add_edit(h.panel_params, "B [Nms/rad]",     params.motor.B,    xL, yL); yL = yL - 0.075;

  add_section(h.panel_params, "Averaged inverter", xL, yL); yL = yL - 0.055;
  h.Vdc  = add_edit(h.panel_params, "Vdc [V]",         params.inv.Vdc,    xL, yL); yL = yL - 0.055;
  h.Imax = add_edit(h.panel_params, "Imax [A]",        params.inv.Imax,   xL, yL); yL = yL - 0.075;

  add_section(h.panel_params, "Operation", xL, yL); yL = yL - 0.055;
  h.mode = add_popup(h.panel_params, "Mode", {"Basic FOC", "FOC + MTPA"}, params.sim.control_mode, xL, yL); yL = yL - 0.055;

  % Right column: control and simulation profile.
  add_section(h.panel_params, "Control", xR, yR); yR = yR - 0.055;
  h.Kp_id = add_edit(h.panel_params, "Kp id",          params.ctrl.Kp_id, xR, yR); yR = yR - 0.055;
  h.Ki_id = add_edit(h.panel_params, "Ki id",          params.ctrl.Ki_id, xR, yR); yR = yR - 0.055;
  h.Kp_iq = add_edit(h.panel_params, "Kp iq",          params.ctrl.Kp_iq, xR, yR); yR = yR - 0.055;
  h.Ki_iq = add_edit(h.panel_params, "Ki iq",          params.ctrl.Ki_iq, xR, yR); yR = yR - 0.055;
  h.Kp_w  = add_edit(h.panel_params, "Kp speed",       params.ctrl.Kp_w,  xR, yR); yR = yR - 0.055;
  h.Ki_w  = add_edit(h.panel_params, "Ki speed",       params.ctrl.Ki_w,  xR, yR); yR = yR - 0.075;

  add_section(h.panel_params, "Profile", xR, yR); yR = yR - 0.055;
  h.t_final = add_edit(h.panel_params, "t_final [s]",  params.sim.t_final,      xR, yR); yR = yR - 0.055;
  h.dt      = add_edit(h.panel_params, "dt [s]",       params.sim.dt,           xR, yR); yR = yR - 0.055;
  h.solver  = add_popup(h.panel_params, "Solver",      {"Euler", "RK4"},       params.sim.solver, xR, yR); yR = yR - 0.055;
  h.wref    = add_edit(h.panel_params, "omega_ref [rpm]", params.sim.wref_rpm,  xR, yR); yR = yR - 0.055;
  h.t_step_w = add_edit(h.panel_params, "t_step_w [s]", params.sim.t_step_w,    xR, yR); yR = yR - 0.055;
  h.Tload   = add_edit(h.panel_params, "Tload [Nm]",   params.sim.Tload,        xR, yR); yR = yR - 0.055;
  h.t_step_load = add_edit(h.panel_params, "t_load [s]", params.sim.t_step_load, xR, yR); yR = yR - 0.055;

  h.run = uicontrol( ...
    "parent", h.panel_actions, ...
    "style", "pushbutton", ...
    "string", "Run", ...
    "units", "normalized", ...
    "position", [0.05 0.78 0.26 0.15], ...
    "callback", {@run_callback, h.fig});

  h.reset = uicontrol( ...
    "parent", h.panel_actions, ...
    "style", "pushbutton", ...
    "string", "Reset", ...
    "units", "normalized", ...
    "position", [0.37 0.78 0.26 0.15], ...
    "callback", {@reset_callback, h.fig});

  h.save = uicontrol( ...
    "parent", h.panel_actions, ...
    "style", "pushbutton", ...
    "string", "Save", ...
    "units", "normalized", ...
    "position", [0.69 0.78 0.26 0.15], ...
    "enable", "off", ...
    "callback", {@save_results_callback, h.fig});

  h.compute_time = uicontrol( ...
    "parent", h.panel_actions, ...
    "style", "text", ...
    "string", "Computation time: --", ...
    "units", "normalized", ...
    "horizontalalignment", "left", ...
    "position", [0.05 0.56 0.90 0.18]);

  h.status = uicontrol( ...
    "parent", h.panel_actions, ...
    "style", "text", ...
    "string", "Ready. Averaged inverter. Solver: Euler. Mode: Basic FOC (id*=0).", ...
    "units", "normalized", ...
    "horizontalalignment", "left", ...
    "position", [0.05 0.10 0.90 0.44]);

  h.ax_speed = axes("parent", h.panel_plots, "position", [0.08 0.58 0.40 0.34]);
  title(h.ax_speed, "Speed"); grid(h.ax_speed, "on");

  h.ax_curr = axes("parent", h.panel_plots, "position", [0.56 0.58 0.38 0.34]);
  title(h.ax_curr, "dq currents"); grid(h.ax_curr, "on");

  h.ax_torque = axes("parent", h.panel_plots, "position", [0.08 0.10 0.40 0.34]);
  title(h.ax_torque, "Torque"); grid(h.ax_torque, "on");

  h.ax_voltage = axes("parent", h.panel_plots, "position", [0.56 0.10 0.38 0.34]);
  title(h.ax_voltage, "dq voltage"); grid(h.ax_voltage, "on");

  guidata(h.fig, h);

  % Run once at startup so that the GUI opens with initial results.
  run_callback([], [], h.fig);
end

function add_section(parent, label, x, y)
  uicontrol( ...
    "parent", parent, ...
    "style", "text", ...
    "string", label, ...
    "units", "normalized", ...
    "fontweight", "bold", ...
    "horizontalalignment", "left", ...
    "position", [x y 0.42 0.040]);
end

function h_edit = add_edit(parent, label, value, x, y)
  uicontrol( ...
    "parent", parent, ...
    "style", "text", ...
    "string", label, ...
    "units", "normalized", ...
    "horizontalalignment", "left", ...
    "position", [x y 0.245 0.040]);

  h_edit = uicontrol( ...
    "parent", parent, ...
    "style", "edit", ...
    "string", num2str(value, 8), ...
    "units", "normalized", ...
    "position", [x + 0.260 y 0.175 0.042]);
end

function h_popup = add_popup(parent, label, options, default_value, x, y)
  uicontrol( ...
    "parent", parent, ...
    "style", "text", ...
    "string", label, ...
    "units", "normalized", ...
    "horizontalalignment", "left", ...
    "position", [x y 0.245 0.040]);

  idx = 1;
  for k = 1:length(options)
    if strcmpi(options{k}, default_value)
      idx = k;
    endif
  endfor

  h_popup = uicontrol( ...
    "parent", parent, ...
    "style", "popupmenu", ...
    "string", options, ...
    "value", idx, ...
    "units", "normalized", ...
    "position", [x + 0.260 y 0.175 0.042]);
end

function params = default_params()
  % Example IPMSM parameters for a small/medium lab drive.
  params.motor.Rs = 0.25;
  params.motor.Ld = 0.0008;
  params.motor.Lq = 0.0016;
  params.motor.psif = 0.055;
  params.motor.p = 4;
  params.motor.J = 0.0015;
  params.motor.B = 0.0002;

  params.inv.Vdc = 300;
  params.inv.Imax = 40;

  % Conservative PI gains for the example parameters.
  params.ctrl.Kp_id = 3.0;
  params.ctrl.Ki_id = 600;
  params.ctrl.Kp_iq = 3.0;
  params.ctrl.Ki_iq = 600;
  params.ctrl.Kp_w  = 0.06;
  params.ctrl.Ki_w  = 2.0;

  params.sim.t_final = 0.5;
  params.sim.dt = 1e-5;
  params.sim.solver = "Euler";
  params.sim.control_mode = "Basic FOC";
  params.sim.wref_rpm = 3000;
  params.sim.t_step_w = 0.02;
  params.sim.Tload = 3.0;
  params.sim.t_step_load = 0.25;
end

function reset_callback(src, evt, fig)
  h = guidata(fig);
  params = default_params();

  set(h.Rs, "string", num2str(params.motor.Rs, 8));
  set(h.Ld, "string", num2str(params.motor.Ld, 8));
  set(h.Lq, "string", num2str(params.motor.Lq, 8));
  set(h.psif, "string", num2str(params.motor.psif, 8));
  set(h.p, "string", num2str(params.motor.p, 8));
  set(h.J, "string", num2str(params.motor.J, 8));
  set(h.B, "string", num2str(params.motor.B, 8));

  set(h.Vdc, "string", num2str(params.inv.Vdc, 8));
  set(h.Imax, "string", num2str(params.inv.Imax, 8));

  set(h.mode, "value", 1);

  set(h.Kp_id, "string", num2str(params.ctrl.Kp_id, 8));
  set(h.Ki_id, "string", num2str(params.ctrl.Ki_id, 8));
  set(h.Kp_iq, "string", num2str(params.ctrl.Kp_iq, 8));
  set(h.Ki_iq, "string", num2str(params.ctrl.Ki_iq, 8));
  set(h.Kp_w, "string", num2str(params.ctrl.Kp_w, 8));
  set(h.Ki_w, "string", num2str(params.ctrl.Ki_w, 8));

  set(h.t_final, "string", num2str(params.sim.t_final, 8));
  set(h.dt, "string", num2str(params.sim.dt, 8));
  set(h.solver, "value", 1);
  set(h.wref, "string", num2str(params.sim.wref_rpm, 8));
  set(h.t_step_w, "string", num2str(params.sim.t_step_w, 8));
  set(h.Tload, "string", num2str(params.sim.Tload, 8));
  set(h.t_step_load, "string", num2str(params.sim.t_step_load, 8));

  set(h.status, "string", "Values restored. Running simulation...");
  set(h.compute_time, "string", "Computation time: --");
  set(h.save, "enable", "off");
  run_callback([], [], fig);
end

function run_callback(src, evt, fig)
  h = guidata(fig);
  try
    params = read_gui_params(h);
    validate_params(params);
    set(h.status, "string", ["Running simulation with " params.sim.solver " | " params.sim.control_mode "..."]);
    set(h.compute_time, "string", "Computation time: calculating...");
    set(h.save, "enable", "off");
    drawnow();

    tic();
    results = simulate_foc_gui2(params);
    compute_time_s = toc();

    update_plots(h, results, params);

    Vmax = params.inv.Vdc / sqrt(3);
    sat_pct = 100 * sum(results.sat_v) / length(results.sat_v);
    msg = sprintf(["Done. Solver=%s | Mode=%s | Vmax=%.2f V | max(Is)=%.2f A | max(Vs)=%.2f V | satV=%.1f%%"], ...
                  params.sim.solver, params.sim.control_mode, Vmax, max(results.Is), max(results.Vs), sat_pct);
    time_msg = sprintf("Computation time: %.4f s", ...
                       compute_time_s);
    set(h.status, "string", msg);
    set(h.compute_time, "string", time_msg);

    h.last_results = results;
    h.last_params = params;
    h.last_compute_time_s = compute_time_s;
    set(h.save, "enable", "on");
    guidata(fig, h);
  catch err
    set(h.status, "string", ["Error: " err.message]);
    set(h.compute_time, "string", "Computation time: --");
    try
      errordlg(err.message, "Simulation error");
    catch
      disp(err.message);
    end_try_catch
  end_try_catch
end

function save_results_callback(src, evt, fig)
  h = guidata(fig);

  if !isfield(h, "last_results") || isempty(h.last_results)
    set(h.status, "string", "No results to save. Run a simulation first.");
    return;
  endif

  results = h.last_results;
  params = h.last_params;
  compute_time_s = h.last_compute_time_s;

  default_name = ["foc_gui2_results_" datestr(now(), "yyyymmdd_HHMMSS") ".mat"];

  try
    [fname, fpath] = uiputfile({"*.mat", "Octave/MAT file (*.mat)"; ...
                                "*.csv", "CSV file (*.csv)"}, ...
                               "Save simulation results", default_name);
  catch
    fname = default_name;
    fpath = pwd();
  end_try_catch

  if isequal(fname, 0) || isequal(fpath, 0)
    set(h.status, "string", "Save canceled.");
    return;
  endif

  filename = fullfile(fpath, fname);
  [~, ~, ext] = fileparts(filename);

  if isempty(ext)
    filename = [filename ".mat"];
    ext = ".mat";
  endif

  try
    if strcmpi(ext, ".csv")
      write_results_csv(filename, results);
      params_file = strrep(filename, ".csv", "_params.mat");
      save(params_file, "params", "compute_time_s");
      set(h.status, "string", ["CSV results saved: " filename " | parameters: " params_file]);
    else
      save(filename, "results", "params", "compute_time_s");
      set(h.status, "string", ["Results saved: " filename]);
    endif
  catch err
    set(h.status, "string", ["Save error: " err.message]);
    try
      errordlg(err.message, "Save results error");
    catch
      disp(err.message);
    end_try_catch
  end_try_catch
end

function write_results_csv(filename, r)
  fid = fopen(filename, "w");
  if fid < 0
    error(["Could not open file: " filename]);
  endif

  fprintf(fid, ["t_s,wref_rpm,wm_rpm,id_ref_A,id_A,iq_ref_A,iq_A," ...
                "Is_ref_A,Is_A,Tref_Nm,Te_Nm,Tload_Nm,vd_V,vq_V,Vs_V,Vmax_V,sat_v,sat_i\n"]);

  wm_rpm = radps_to_rpm(r.wm);
  wref_rpm = radps_to_rpm(r.wref);

  M = [r.t(:), wref_rpm(:), wm_rpm(:), ...
       r.id_ref(:), r.id(:), r.iq_ref(:), r.iq(:), ...
       r.Is_ref(:), r.Is(:), ...
       r.Tref(:), r.Te(:), r.Tload(:), ...
       r.vd(:), r.vq(:), r.Vs(:), r.Vmax(:), ...
       double(r.sat_v(:)), double(r.sat_i(:))];

  fmt = [repmat("%.12g,", 1, columns(M)-1) "%.12g\n"];
  fprintf(fid, fmt, M');
  fclose(fid);
end

function params = read_gui_params(h)
  params.motor.Rs = read_number(h.Rs, "Rs");
  params.motor.Ld = read_number(h.Ld, "Ld");
  params.motor.Lq = read_number(h.Lq, "Lq");
  params.motor.psif = read_number(h.psif, "psi_f");
  params.motor.p = read_number(h.p, "pole pairs");
  params.motor.J = read_number(h.J, "J");
  params.motor.B = read_number(h.B, "B");

  params.inv.Vdc = read_number(h.Vdc, "Vdc");
  params.inv.Imax = read_number(h.Imax, "Imax");

  params.sim.control_mode = read_popup(h.mode);

  params.ctrl.Kp_id = read_number(h.Kp_id, "Kp id");
  params.ctrl.Ki_id = read_number(h.Ki_id, "Ki id");
  params.ctrl.Kp_iq = read_number(h.Kp_iq, "Kp iq");
  params.ctrl.Ki_iq = read_number(h.Ki_iq, "Ki iq");
  params.ctrl.Kp_w = read_number(h.Kp_w, "Kp speed");
  params.ctrl.Ki_w = read_number(h.Ki_w, "Ki speed");

  params.sim.t_final = read_number(h.t_final, "t_final");
  params.sim.dt = read_number(h.dt, "dt");
  params.sim.solver = read_popup(h.solver);
  params.sim.wref_rpm = read_number(h.wref, "omega_ref");
  params.sim.t_step_w = read_number(h.t_step_w, "t_step_w");
  params.sim.Tload = read_number(h.Tload, "Tload");
  params.sim.t_step_load = read_number(h.t_step_load, "t_step_load");
end

function value = read_number(handle, name)
  value = str2double(get(handle, "string"));
  if isnan(value)
    error(["Non-numeric parameter: " name]);
  endif
end

function value = read_popup(handle)
  entries = get(handle, "string");
  idx = get(handle, "value");
  if iscell(entries)
    value = entries{idx};
  else
    value = strtrim(entries(idx, :));
  endif
end

function validate_params(params)
  if params.motor.Rs <= 0, error("Rs must be greater than zero."); endif
  if params.motor.Ld <= 0, error("Ld must be greater than zero."); endif
  if params.motor.Lq <= 0, error("Lq must be greater than zero."); endif
  if params.motor.psif <= 0, error("psi_f must be greater than zero."); endif
  if params.motor.p <= 0, error("The number of pole pairs must be greater than zero."); endif
  if params.motor.J <= 0, error("J must be greater than zero."); endif
  if params.inv.Vdc <= 0, error("Vdc must be greater than zero."); endif
  if params.inv.Imax <= 0, error("Imax must be greater than zero."); endif
  if params.sim.dt <= 0, error("dt must be greater than zero."); endif
  if params.sim.t_final <= params.sim.dt, error("t_final must be greater than dt."); endif
  if params.sim.t_final / params.sim.dt > 200000
    error("Too many steps. Increase dt or reduce t_final.");
  endif
end

function results = simulate_foc_gui2(params)
  s = params.sim;

  N = floor(s.t_final / s.dt) + 1;
  t = (0:N-1) * s.dt;

  % Closed-loop state vector:
  % x = [id; iq; wm; xi_d; xi_q; xi_w]
  x = zeros(6, 1);

  Vmax = params.inv.Vdc / sqrt(3);

  results.t = t;
  results.id = zeros(1, N);
  results.iq = zeros(1, N);
  results.id_ref = zeros(1, N);
  results.iq_ref = zeros(1, N);
  results.Is_ref = zeros(1, N);
  results.wm = zeros(1, N);
  results.wref = zeros(1, N);
  results.Te = zeros(1, N);
  results.Tref = zeros(1, N);
  results.Tload = zeros(1, N);
  results.vd = zeros(1, N);
  results.vq = zeros(1, N);
  results.Vs = zeros(1, N);
  results.Vmax = Vmax * ones(1, N);
  results.Is = zeros(1, N);
  results.sat_v = false(1, N);
  results.sat_i = false(1, N);

  for k = 1:N
    tk = t(k);
    [dx, out] = closed_loop_rhs(tk, x, params);

    % Store current sample.
    results.id(k) = x(1);
    results.iq(k) = x(2);
    results.wm(k) = x(3);
    results.id_ref(k) = out.id_ref;
    results.iq_ref(k) = out.iq_ref;
    results.Is_ref(k) = out.Is_ref;
    results.wref(k) = out.wref;
    results.Te(k) = out.Te;
    results.Tref(k) = out.Tref;
    results.Tload(k) = out.Tload;
    results.vd(k) = out.vd;
    results.vq(k) = out.vq;
    results.Vs(k) = out.Vs;
    results.Is(k) = sqrt(x(1)^2 + x(2)^2);
    results.sat_v(k) = out.sat_v;
    results.sat_i(k) = out.sat_i;

    if k < N
      if strcmpi(s.solver, "RK4")
        x = rk4_step(@closed_loop_rhs, tk, x, s.dt, params);
      else
        x = x + s.dt * dx;
      endif
      x = post_step_clamp(x, params);
    endif
  endfor
end

function x_next = rk4_step(rhs_fun, t, x, h, params)
  k1 = rhs_fun(t,           x,               params);
  k2 = rhs_fun(t + 0.5*h,   x + 0.5*h*k1,    params);
  k3 = rhs_fun(t + 0.5*h,   x + 0.5*h*k2,    params);
  k4 = rhs_fun(t + h,       x + h*k3,        params);
  x_next = x + (h/6) * (k1 + 2*k2 + 2*k3 + k4);
end

function [dx, out] = closed_loop_rhs(t, x, params)
  m = params.motor;
  inv = params.inv;
  c = params.ctrl;
  s = params.sim;

  id = x(1);
  iq = x(2);
  wm = x(3);
  xi_d = x(4);
  xi_q = x(5);
  xi_w = x(6);

  Vmax = inv.Vdc / sqrt(3);       % Linear SVM averaged voltage limit.

  if t >= s.t_step_w
    wref = rpm_to_radps(s.wref_rpm);
  else
    wref = 0;
  endif

  if t >= s.t_step_load
    Tload = s.Tload;
  else
    Tload = 0;
  endif

  % Outer speed PI. The output is interpreted as a signed stator current
  % magnitude command. This matches the MTPA block structure, where a current
  % command is split into id* and iq*.
  e_w = wref - wm;
  Is_ref_unsat = c.Kp_w * e_w + xi_w;
  Is_ref = clamp(Is_ref_unsat, -inv.Imax, inv.Imax);
  dxi_w = antiwindup_derivative(c.Ki_w * e_w, Is_ref_unsat, -inv.Imax, inv.Imax);
  sat_i = abs(Is_ref_unsat) > inv.Imax;

  if strcmpi(s.control_mode, "FOC + MTPA")
    [id_ref, iq_ref] = mtpa_current_reference(Is_ref, m);
  else
    id_ref = 0;
    iq_ref = Is_ref;
  endif

  % Torque associated with the current references. This is displayed as T*.
  Tref = electromagnetic_torque(id_ref, iq_ref, m);

  % Inner current PI controllers.
  e_d = id_ref - id;
  e_q = iq_ref - iq;

  vd_pi_unsat = c.Kp_id * e_d + xi_d;
  vq_pi_unsat = c.Kp_iq * e_q + xi_q;

  dxi_d = antiwindup_derivative(c.Ki_id * e_d, vd_pi_unsat, -Vmax, Vmax);
  dxi_q = antiwindup_derivative(c.Ki_iq * e_q, vq_pi_unsat, -Vmax, Vmax);

  vd_pi = clamp(vd_pi_unsat, -Vmax, Vmax);
  vq_pi = clamp(vq_pi_unsat, -Vmax, Vmax);

  we = m.p * wm;

  % Decoupling feedforward in the dq frame.
  vd_cmd = vd_pi - we * m.Lq * iq;
  vq_cmd = vq_pi + we * (m.Ld * id + m.psif);

  [vd, vq, sat_v] = limit_voltage(vd_cmd, vq_cmd, Vmax);

  % IPMSM electrical and mechanical state equations in the dq frame.
  did = (vd - m.Rs * id + we * m.Lq * iq) / m.Ld;
  diq = (vq - m.Rs * iq - we * (m.Ld * id + m.psif)) / m.Lq;
  Te = electromagnetic_torque(id, iq, m);
  dwm = (Te - Tload - m.B * wm) / m.J;

  dx = [did; diq; dwm; dxi_d; dxi_q; dxi_w];

  out.id_ref = id_ref;
  out.iq_ref = iq_ref;
  out.Is_ref = abs(Is_ref);
  out.wref = wref;
  out.Tload = Tload;
  out.Tref = Tref;
  out.Te = Te;
  out.vd = vd;
  out.vq = vq;
  out.Vs = sqrt(vd^2 + vq^2);
  out.sat_v = sat_v;
  out.sat_i = sat_i;
end

function [id_ref, iq_ref] = mtpa_current_reference(Is_ref_signed, m)
  % MTPA reference generation for a non-saturated IPMSM with Lq > Ld.
  % The input is a signed stator-current magnitude. Positive values produce
  % positive q-axis current and positive electromagnetic torque.
  Is = abs(Is_ref_signed);
  if Is <= 0
    id_ref = 0;
    iq_ref = 0;
    return;
  endif

  dL = m.Lq - m.Ld;
  if dL <= 1e-12
    % Surface PMSM or non-salient case: MTPA degenerates to id*=0.
    id_ref = 0;
    iq_ref = Is_ref_signed;
    return;
  endif

  id_ref = (m.psif - sqrt(m.psif^2 + 8 * dL^2 * Is^2)) / (4 * dL);
  iq_abs = sqrt(max(Is^2 - id_ref^2, 0));
  iq_ref = sign_nonzero(Is_ref_signed) * iq_abs;
end

function Te = electromagnetic_torque(id, iq, m)
  Te = 1.5 * m.p * (m.psif * iq + (m.Ld - m.Lq) * id * iq);
end

function sgn = sign_nonzero(x)
  if x < 0
    sgn = -1;
  else
    sgn = 1;
  endif
end

function dxi = antiwindup_derivative(dxi_raw, u_unsat, umin, umax)
  % Conditional integration: stop the integrator only when the controller
  % output is beyond a limit and the integrator would push it farther away.
  if (u_unsat >= umax && dxi_raw > 0) || (u_unsat <= umin && dxi_raw < 0)
    dxi = 0;
  else
    dxi = dxi_raw;
  endif
end

function x = post_step_clamp(x, params)
  Vmax = params.inv.Vdc / sqrt(3);

  % Clamp only controller integrator states. The physical states id, iq, wm
  % are left untouched; they evolve according to the plant equations.
  x(4) = clamp(x(4), -Vmax, Vmax);
  x(5) = clamp(x(5), -Vmax, Vmax);
  x(6) = clamp(x(6), -params.inv.Imax, params.inv.Imax);
end

function [vd_lim, vq_lim, saturated] = limit_voltage(vd, vq, Vmax)
  Vs = sqrt(vd^2 + vq^2);
  if Vs > Vmax && Vs > 0
    scale = Vmax / Vs;
    vd_lim = vd * scale;
    vq_lim = vq * scale;
    saturated = true;
  else
    vd_lim = vd;
    vq_lim = vq;
    saturated = false;
  endif
end

function update_plots(h, r, params)
  t = r.t;
  rpm = radps_to_rpm(r.wm);
  rpm_ref = radps_to_rpm(r.wref);

  axes(h.ax_speed);
  cla(h.ax_speed);
  plot(h.ax_speed, t, rpm_ref, "--", t, rpm, "-");
  xlabel(h.ax_speed, "t [s]"); ylabel(h.ax_speed, "rpm");
  title(h.ax_speed, ["Mechanical speed - " params.sim.solver " - " params.sim.control_mode]);
  legend(h.ax_speed, "ref", "motor"); grid(h.ax_speed, "on");

  axes(h.ax_curr);
  cla(h.ax_curr);
  plot(h.ax_curr, t, r.id_ref, "--", t, r.id, "-", t, r.iq_ref, "--", t, r.iq, "-", t, sqrt(r.id.^2+r.iq.^2), "-.");
  xlabel(h.ax_curr, "t [s]"); ylabel(h.ax_curr, "A");
  title(h.ax_curr, "dq currents");
  legend(h.ax_curr, "id*", "id", "iq*", "iq", "Is"); grid(h.ax_curr, "on");

  axes(h.ax_torque);
  cla(h.ax_torque);
  plot(h.ax_torque, t, r.Tref, "--", t, r.Te, "-", t, r.Tload, ":");
  xlabel(h.ax_torque, "t [s]"); ylabel(h.ax_torque, "Nm");
  title(h.ax_torque, "Torque");
  legend(h.ax_torque, "T* from current refs", "Te", "Tload"); grid(h.ax_torque, "on");

  axes(h.ax_voltage);
  cla(h.ax_voltage);
  plot(h.ax_voltage, t, r.vd, "-", t, r.vq, "-", t, r.Vs, "-", t, r.Vmax, "--");
  xlabel(h.ax_voltage, "t [s]"); ylabel(h.ax_voltage, "V");
  title(h.ax_voltage, "Averaged dq voltage");
  legend(h.ax_voltage, "vd", "vq", "Vs", "Vmax"); grid(h.ax_voltage, "on");

  drawnow();
end

function y = clamp(x, xmin, xmax)
  y = min(max(x, xmin), xmax);
end

function w = rpm_to_radps(rpm)
  w = rpm * 2*pi/60;
end

function rpm = radps_to_rpm(w)
  rpm = w * 60/(2*pi);
end
