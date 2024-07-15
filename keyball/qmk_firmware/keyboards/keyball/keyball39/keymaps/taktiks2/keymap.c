/*
Copyright 2022 @Yowkees
Copyright 2022 MURAOKA Taro (aka KoRoN, @kaoriya)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include QMK_KEYBOARD_H

#include "quantum.h"

// clang-format off
const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
  // keymap for default
  [0] = LAYOUT_universal(
    KC_Q     , KC_W     , KC_E     , KC_R     , KC_T     ,                            KC_Y     , KC_U     , KC_I     , KC_O     , KC_P     ,
    KC_A     , KC_S     , KC_D     , KC_F     , KC_G     ,                            KC_H     , KC_J     , KC_K     , KC_L     , KC_ENT  ,
    KC_Z     , KC_X     , KC_C     , KC_V     , KC_B     ,                            KC_N     , KC_M     , KC_BTN1  , KC_BTN2  , LT(3, KC_SCLN),
    KC_LSFT  , KC_LALT  , KC_MINS  , LT(1, KC_SLSH), CTL_T(KC_ESC),LT(2, KC_TAB),KC_RGUI ,KC_SPC, _______  , _______  , _______ , KC_RSFT
  ),

  [1] = LAYOUT_universal(
    KC_EXLM  , KC_AT    , KC_HASH  , KC_DLR   , KC_PERC  ,                            KC_QUOT  , KC_LPRN  , KC_RPRN  , KC_LT    , KC_GT    ,
    _______  , _______  , _______  , KC_CIRC  , KC_TILD  ,                            KC_DQUO  , KC_LCBR  , KC_RCBR  , KC_AMPR  , KC_PIPE  ,
    _______  , _______  , _______  , _______  , _______  ,                            KC_GRV   , KC_LBRC  , KC_RBRC  , KC_COMM  , KC_DOT   ,
    _______  , _______  , _______  , _______  , _______  , _______  ,      _______  , _______  , _______  , _______  , _______  , KC_PSLS
  ),

  [2] = LAYOUT_universal(
    KC_F1    , KC_F2    , KC_F3    , KC_F4    , KC_F5    ,                            KC_PPLS  , KC_P7    , KC_P8    , KC_P9    , KC_BSPC  ,
    KC_F6    , KC_F7    , KC_F8    , KC_F9    , KC_F10   ,                            KC_PAST  , KC_P4    , KC_P5    , KC_P6    , KC_P0    ,
    _______  , _______  , _______  , KC_F11   , KC_F12   ,                            KC_PMNS  , KC_P1    , KC_P2    , KC_P3    , KC_PEQL  ,
    _______  , _______  , _______  , _______  , _______  , _______  ,      _______  , _______  , _______  , _______  , _______  , _______
  ),

  [3] = LAYOUT_universal(
    _______  , _______  , _______  , _______  , _______  ,                            _______  , _______  , _______  , _______  , _______  ,
    _______  , _______  , _______  , _______  , _______  ,                            _______  , _______  , KC_UP    , _______  , _______  ,
    _______  , _______  , _______  , _______  , _______  ,                            _______  , KC_LEFT  , KC_DOWN  , KC_RIGHT , _______  ,
    _______  , _______  , _______  , _______  , _______  , _______  ,      _______  , _______  , _______  , _______  , _______  , _______
  ),
};
// clang-format on

layer_state_t layer_state_set_user(layer_state_t state) {
    // Auto enable scroll mode when the highest layer is 3
    keyball_set_scroll_mode(get_highest_layer(state) == 3);
    return state;
}


#ifdef OLED_ENABLE

#include "lib/oledkit/oledkit.h"

/* oled_rotation_t oled_init_user(oled_rotation_t rotation) { */
/*     if (is_keyboard_master()) { */
/*       return rotation; */
/*     } else { */
/*       return OLED_ROTATION_270; */
/*     } */
/* } */

/* void oled_render_layer_state(void) { */
/*     switch (get_highest_layer(layer_state)) { */
/*         case 0: */
/*             oled_write_ln_P(PSTR("Base"), false); */
/*             break; */
/*         case 1: */
/*             oled_write_ln_P(PSTR("Layer 1"), false); */
/*             break; */
/*         case 2: */
/*             oled_write_ln_P(PSTR("Layer 2"), false); */
/*             break; */
/*         case 3: */
/*             oled_write_ln_P(PSTR("Layer 3"), false); */
/*             break; */
/*         default: */
/*             oled_write_ln_P(PSTR("Undefined"), false); */
/*             break; */
/*     } */
/* } */

void oledkit_render_info_user(void) {
    keyball_oled_render_keyinfo();
    keyball_oled_render_ballinfo();
    keyball_oled_render_layerinfo();
}

/* bool oled_task_user(void) { */
/*     if (is_keyboard_master()) { */
/*         oledkit_render_info_user(); */
/*     } else { */
/*         oled_render_layer_state(); */
/*     } */
/*     return false; */
/* } */

#endif
