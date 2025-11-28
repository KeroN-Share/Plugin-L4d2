# Description | Miêu tả
 This plugin gives the survivor a chance to slip and fall when jumping. <br/>
 Plugin này cho người sống sót khi nhảy có tỉ lệ sẽ bị trượt chân vấp ngã

* Require | Cài đặt bắt buộc
<br/>None

* <details>
    <summary>How does it work?</summary>

        * Khi người chơi sử dụng hành động nhảy đến một lần cố định sẽ có tỉ lệ % người chơi bị trượt chân và ngã
        * When a player performs a jump a fixed number of times, there is a percentage chance that the player will slip and fall.
  </details>

* <details><summary>ConVar</summary>

    * cfg/sourcemod/l4d2_jump_slip_fling_bykeron.cfg
        ```php
        // Percentage chance (0-100) to fall after reaching the jump limit.
        l4d2_jf_fallchance "30.0"

        // The base force applied to the player fling.
        l4d2_jf_fallvelocity "1000.0"

        // Number of consecutive jumps before a fall chance is applied.
        l4d2_jf_jumplimit "4"

        // Time in seconds before the jump count resets if no jumps are made.
        l4d2_jf_resettime "1.5"

        // Duration (seconds) the fling/stun lasts.
        l4d2_jf_stunduration "2.0"


        ```
</details>

* <details><summary>Changelog | 版本日誌</summary>

    * v1.1 (2025-11-28)

        * Switch code language
