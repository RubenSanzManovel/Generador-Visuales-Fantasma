# ============================================================================
# MIDI_HANDLER.PY - ENTRADA MIDI PARA CONTROLADORA DDJ-SB2
# ============================================================================
# Lee mensajes MIDI desde un puerto virtual y actualiza el estado del
# visualizador con acciones de botones y faders.
# ============================================================================

from __future__ import annotations

from typing import Dict, Any, Optional, Tuple
import random

import config
import mido


class MidiHandler:
    def __init__(self, port_hint: str = "Visuales_Bridge") -> None:
        self.port_hint = port_hint
        self.inport: Optional[mido.ports.BaseInput] = None
        self._connect()

    def _connect(self) -> None:
        target_port = None
        for port in mido.get_input_names():
            if self.port_hint in port:
                target_port = port
                break

        if target_port:
            self.inport = mido.open_input(target_port)
            print(f"MIDI conectado a: {target_port}")
        else:
            print("MIDI no disponible: no se encontro el puerto virtual.")

    def is_active(self) -> bool:
        return self.inport is not None

    def close(self) -> None:
        if self.inport:
            try:
                self.inport.close()
            finally:
                self.inport = None

    def poll(self, state: Dict[str, Any], current_time: float) -> None:
        if not self.inport:
            return

        for msg in self.inport.iter_pending():
            msg_bytes = msg.bytes()
            if len(msg_bytes) < 3:
                continue

            status, data1, data2 = msg_bytes[0], msg_bytes[1], msg_bytes[2]

            # Botones (Note On 0x90-0x9F o Note Off 0x80-0x8F)
            if (status & 0xF0) in (0x90, 0x80):
                # Comprobar si es un botón de efectos (Canal 4 o 5, notas 0x47, 0x48, 0x49)
                is_effect_note = (status & 0x0F) in (4, 5) and data1 in (0x47, 0x48, 0x49)
                
                # Para botones de efectos, procesamos en cualquier evento (ON de 0x7F o OFF de 0x00)
                # Para otros botones estándar, solo procesamos cuando data2 == 0x7F (Note On / Pulsado)
                if is_effect_note or data2 == 0x7F:
                    self._handle_button(state, current_time, status, data1)
                    continue

            # Controles continuos (CC)
            if (status & 0xF0) == 0xB0:
                self._handle_cc(state, current_time, status, data1, data2)

    def _handle_button(self, state: Dict[str, Any], current_time: float, status: int, data1: int) -> None:
        # Normalizar status de Note Off (0x80) a Note On (0x90) para que coincida con las claves del diccionario
        if (status & 0xF0) == 0x80:
            status = (status & 0x0F) | 0x90
            
        key: Tuple[int, int] = (status, data1)

        # Play / Cue
        if key == (0x90, 0x0B):
            self._maybe_randomize_on_play(state, current_time, "left")
            return
        if key == (0x90, 0x0C):
            prev = state.get("prev_pattern_index", state.get("pattern_index", 0))
            state["prev_pattern_index"] = state.get("pattern_index", 0)
            state["pattern_index"] = prev
            state["pattern_change_time"] = current_time
            return
        if key == (0x91, 0x0B):
            self._maybe_randomize_on_play(state, current_time, "right")
            return
        if key == (0x91, 0x0C):
            state["midi_fx_flash_until"] = current_time + 0.25
            return

        # HotCues Izq (FX aleatorio)
        if key == (0x97, 0x00):
            self._trigger_hotcue_fx(state, current_time)
            return
        if key == (0x97, 0x01):
            self._trigger_hotcue_fx(state, current_time)
            return
        if key == (0x97, 0x02):
            self._trigger_hotcue_fx(state, current_time)
            return
        if key == (0x97, 0x03):
            self._trigger_hotcue_fx(state, current_time)
            return

        # HotCues Der (FX aleatorio)
        if key == (0x98, 0x00):
            self._trigger_hotcue_fx(state, current_time)
            return
        if key == (0x98, 0x01):
            self._trigger_hotcue_fx(state, current_time)
            return
        if key == (0x98, 0x02):
            self._trigger_hotcue_fx(state, current_time)
            return
        if key == (0x98, 0x03):
            self._trigger_hotcue_fx(state, current_time)
            return

        # AutoLoop Izq -> glitch
        if key == (0x97, 0x10):
            state["midi_fx_glitch_until"] = current_time + 0.20
            return
        if key == (0x97, 0x11):
            state["midi_fx_glitch_until"] = current_time + 0.40
            return
        if key == (0x97, 0x12):
            state["midi_fx_glitch_until"] = current_time + 0.80
            return
        if key == (0x97, 0x13):
            state["midi_fx_glitch_until"] = current_time + 1.60
            return

        # AutoLoop Der -> strobe
        if key == (0x98, 0x10):
            state["midi_fx_strobe_until"] = current_time + 0.20
            return
        if key == (0x98, 0x11):
            state["midi_fx_strobe_until"] = current_time + 0.40
            return
        if key == (0x98, 0x12):
            state["midi_fx_strobe_until"] = current_time + 0.80
            return
        if key == (0x98, 0x13):
            state["midi_fx_strobe_until"] = current_time + 1.60
            return

        # --- NUEVO MAPEO DE BOTONES DE EFECTOS ---
        # Botones de efectos Deck Izquierdo (Note On 94)
        if key == (0x94, 0x47):
            state["midi_eff1"] = not state.get("midi_eff1", False)
            print(f"[*] MIDI: Efecto 1 (Echo/Trails) {'ON' if state['midi_eff1'] else 'OFF'}")
            return
        if key == (0x94, 0x48):
            state["midi_eff2"] = not state.get("midi_eff2", False)
            print(f"[*] MIDI: Efecto 2 (Reverb/Dispersión) {'ON' if state['midi_eff2'] else 'OFF'}")
            return
        if key == (0x94, 0x49):
            state["midi_eff3"] = not state.get("midi_eff3", False)
            print(f"[*] MIDI: Efecto 3 (Phaser/Separación RGB) {'ON' if state['midi_eff3'] else 'OFF'}")
            return

        # Botones de efectos Deck Derecho (Note On 95)
        if key == (0x95, 0x47):
            state["midi_eff1"] = not state.get("midi_eff1", False)
            print(f"[*] MIDI: Efecto 1 (Echo/Trails) {'ON' if state['midi_eff1'] else 'OFF'}")
            return
        if key == (0x95, 0x48):
            state["midi_eff2"] = not state.get("midi_eff2", False)
            print(f"[*] MIDI: Efecto 2 (Reverb/Dispersión) {'ON' if state['midi_eff2'] else 'OFF'}")
            return
        if key == (0x95, 0x49):
            state["midi_eff3"] = not state.get("midi_eff3", False)
            print(f"[*] MIDI: Efecto 3 (Phaser/Separación RGB) {'ON' if state['midi_eff3'] else 'OFF'}")
            return

    def _handle_cc(self, state: Dict[str, Any], current_time: float, status: int, data1: int, data2: int) -> None:
        value = data2 / 127.0

        # Volumen Izq / Der
        if status == 0xB0 and data1 == 0x13:
            prev = state.get("midi_gain_left", 0.0)
            state["midi_gain_left"] = value
            self._maybe_randomize_on_gain_raise(state, current_time, "left", prev, value)
            return
        if status == 0xB1 and data1 == 0x13:
            prev = state.get("midi_gain_right", 0.0)
            state["midi_gain_right"] = value
            self._maybe_randomize_on_gain_raise(state, current_time, "right", prev, value)
            return

        # Filtro Izq / Der (punto medio 0x40)
        if status == 0xB6 and data1 in (0x17, 0x18):
            is_left = data1 == 0x17
            if data2 == 0x40:
                if is_left:
                    state["midi_filter_lpf_left"] = 0.0
                    state["midi_filter_hpf_left"] = 0.0
                else:
                    state["midi_filter_lpf_right"] = 0.0
                    state["midi_filter_hpf_right"] = 0.0
                return

            if data2 < 0x40:
                intensity = (0x40 - data2) / 64.0
                if is_left:
                    state["midi_filter_lpf_left"] = intensity
                    state["midi_filter_hpf_left"] = 0.0
                else:
                    state["midi_filter_lpf_right"] = intensity
                    state["midi_filter_hpf_right"] = 0.0
            else:
                intensity = (data2 - 0x40) / 63.0
                if is_left:
                    state["midi_filter_hpf_left"] = intensity
                    state["midi_filter_lpf_left"] = 0.0
                else:
                    state["midi_filter_hpf_right"] = intensity
                    state["midi_filter_lpf_right"] = 0.0
            return

        # --- NUEVO MAPEO DE CONTROLES CC DE EQ Y EFECTOS ---
        # Ecualizadores Deck Izquierdo (Status B0)
        if status == 0xB0:
            if data1 == 0x0F: # Low Izq
                state["midi_low_left"] = value
                return
            if data1 == 0x0B: # Mid Izq
                state["midi_mid_left"] = value
                return
            if data1 == 0x07: # High Izq
                state["midi_high_left"] = value
                return

        # Ecualizadores Deck Derecho (Status B1)
        if status == 0xB1:
            if data1 == 0x0F: # Low Der
                state["midi_low_right"] = value
                return
            if data1 == 0x0B: # Mid Der
                state["midi_mid_right"] = value
                return
            if data1 == 0x07: # High Der
                state["midi_high_right"] = value
                return

        # Fader de Intensidad de Efecto Deck Izquierdo (Status B4, CC 0x04)
        if status == 0xB4 and data1 == 0x04:
            state["midi_fadeff_left"] = value
            return

        # Fader de Intensidad de Efecto Deck Derecho (Status B5, CC 0x04)
        if status == 0xB5 and data1 == 0x04:
            state["midi_fadeff_right"] = value
            return

    def _set_pattern(self, state: Dict[str, Any], current_time: float, index: int) -> None:
        state["prev_pattern_index"] = state.get("pattern_index", 0)
        state["pattern_index"] = index
        state["pattern_change_time"] = current_time
        state["midi_pattern_override_time"] = current_time

    def _trigger_hotcue_fx(self, state: Dict[str, Any], current_time: float) -> None:
        fx_type = random.choice(["color_flicker", "zoom_in", "zoom_out"])
        duration = random.choice([0.6, 0.8, 1.0, 1.2])

        state["midi_hotcue_fx"] = fx_type
        state["midi_hotcue_fx_start"] = current_time
        state["midi_hotcue_fx_until"] = current_time + duration
        state["midi_hotcue_fx_seed"] = random.random()

    def _maybe_randomize_on_play(self, state: Dict[str, Any], current_time: float, side: str) -> None:
        threshold = 40 / 127.0
        gain_key = "midi_gain_left" if side == "left" else "midi_gain_right"
        if state.get(gain_key, 0.0) < threshold:
            return

        total = config.TOTAL_PATTERNS
        if total <= 1:
            return

        current = state.get("pattern_index", 0)
        
        # Si estamos en modo random, evitamos repetir patrones recientes
        if state.get("pattern_mode") == "random":
            history = state.get("pattern_history", [])
            excluded = set(history[-20:])
            excluded.add(current)
            
            candidates = [i for i in range(total) if i not in excluded]
            
            # Si no hay candidatos, reducimos el rango de exclusión progresivamente
            history_limit = 20
            while not candidates and history_limit > 0:
                history_limit -= 1
                excluded = set(history[-history_limit:])
                excluded.add(current)
                candidates = [i for i in range(total) if i not in excluded]
                
            if candidates:
                new_index = random.choice(candidates)
            else:
                new_index = random.randint(0, total - 1)
                while new_index == current and total > 1:
                    new_index = random.randint(0, total - 1)
            
            # Registrar en historial
            history = state.setdefault("pattern_history", [])
            history.append(new_index)
            if len(history) > 50:
                state["pattern_history"] = history[-50:]
        else:
            new_index = random.randint(0, total - 1)
            while new_index == current and total > 1:
                new_index = random.randint(0, total - 1)

        self._set_pattern(state, current_time, new_index)

    def _maybe_randomize_on_gain_raise(
        self,
        state: Dict[str, Any],
        current_time: float,
        side: str,
        prev_value: float,
        new_value: float,
    ) -> None:
        threshold = 40 / 127.0
        if prev_value < threshold and new_value >= threshold:
            self._maybe_randomize_on_play(state, current_time, side)
