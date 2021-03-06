/**
 * Progress Status Text by John Parker
 * Version 1.2
 *
 * This script displays a progress bar above a prim, with support for a marquee
 * animation.
 *
 * See readme file for usage instructions.
 *
 * Change history:
 *
 *    23/11/2019 - Updated marquee progress bar to show a 4-block trail instead
 *                 of just 1 block moving left-to-right. Bumped version to 1.1.
 *
 *    02/12/2019 - Replaced link message system with JSON version that supports
 *                 multiple parameters in one message. Improved a few comments.
 *                 Bumped version to 1.2.
 *
 * Licence:
 *
 *   MIT License
 *
 *   Copyright (c) 2020 John Parker
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 *   
 *   The above copyright notice and this permission notice shall be included in all
 *   copies or substantial portions of the Software.
 *   
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
**/

/**
 * Link message identifier
**/
#define PROGRESS_STATUS_MESSAGE -800100

/**
 * Configuration settings
**/
integer link_number = LINK_THIS;
string progress_text = "";
integer progress_value = 0;
integer progress_marquee = FALSE;
integer progress_marquee_state = 0;
vector progress_color = <1, 1, 1>;
integer auto_update = TRUE;

/**
 * This prevents Top Scripts and script-memory checkers from seeing this script
 * as a memory hog.
**/
#define set_memory_limit() llSetMemoryLimit( llGetUsedMemory() + 2048 )

/**
 * Update the floating text currently on the prim to show the current progress
 * state.
**/
update_progress()
{
    set_memory_limit();

    //
    // Check for marquee animation and handle separately.
    //
    if( progress_marquee )
    {
        string progress_markers = "";

        //
        // This code can be hard to wrap your head around. We need to create a
        // 4-block marquee across a 20-block progress bar.
        //
        // When the state is < 4, we only need to show UP TO 4 filled blocks.
        // So, if state = 1, we need 1 block, state = 2, we need 2 blocks, etc.
        // until we get to 4. The rest are unfilled blocks.
        //
        // But, if the state is >= 4, then we have to show a "trail" of 4 blocks
        // "moving" along the 20-block bar. This is accomplished by adding unfilled
        // blocks before the trail, THEN adding the trail, THEN adding the rest.
        //
        // However, if the state is > 20, we have gone OVER how many blocks we
        // need to show, so we calculate how many filled blocks to show first
        // which is 4 - ( state - 20 ). This is because state - 20 is how many
        // blocks we DON'T need, took away from 4 which is the MAXIMUM amount of
        // filled blocks we want to show. This can be simplified to -state + 24.
        //
        // Yay, mathematics! *cough*.
        //

        if( progress_marquee_state < 4 )
        {
            integer filled_chars = progress_marquee_state;

            integer i;
            for( i = 0; i < filled_chars; i++ )
            {
                progress_markers += "█";
            }

            integer unfilled_chars = 20 - filled_chars;
            for( i = 0; i < unfilled_chars; i++ )
            {
                progress_markers += "░";
            }
        }
        else
        {
            integer unfilled_chars = progress_marquee_state - 4;
            
            integer i;
            for( i = 0; i < unfilled_chars; i++ )
            {
                progress_markers += "░";
            }

            if( progress_marquee_state > 20 )
            {
                integer filled_chars = -progress_marquee_state + 24;
                for( i = 0; i < filled_chars; i++ )
                {
                    progress_markers += "█";
                }
            }
            else
            {
                progress_markers += "████";
                i += 4;

                for( ; i < 20; i++ )
                {
                    progress_markers += "░";
                }
            }
        }
        
        llSetLinkPrimitiveParamsFast(
            link_number,
            [
                PRIM_TEXT, progress_text + "\n" + progress_markers, progress_color, 1.0
            ]
        );
    }
    else
    {
        //
        // Progress value is percentage out of 100.
        //
        integer progress_value_count = llRound( ( (float)progress_value / 100 ) * 20 );
        string progress_markers = "";

        integer i;
        for( i = 0; i < progress_value_count; i++ )
        {
            progress_markers += "█";
        }

        for( ; i < 20; i++ )
        {
            progress_markers += "░";
        }

        llSetLinkPrimitiveParamsFast(
            link_number,
            [
                PRIM_TEXT, progress_text + "\n" + progress_markers, progress_color, 1.0
            ]
        );
    }
}

default
{
    state_entry()
    {
        set_memory_limit();
    }

    on_rez( integer start_param )
    {
        llResetScript();
    }

    link_message( integer sender_num, integer num, string str, key id )
    {
        if( num != PROGRESS_STATUS_MESSAGE )
            return;
        
        set_memory_limit();
        
        //
        // Reset
        //
        // Specifying this parameter will ignore all other parameters and
        // reset the script.
        //
        if( (integer)llJsonGetValue( str, [ "reset" ] ) )
            llResetScript();

        //
        // Link number
        //
        string link_num_str = llJsonGetValue( str, [ "link" ] );
        if( link_num_str != JSON_INVALID )
        {
            link_number = (integer)link_num_str;

            if( link_number == 0 )
                link_number = LINK_THIS;
        }

        //
        // Text
        //
        string progress_text_str = llJsonGetValue( str, [ "text" ] );
        if( progress_text_str != JSON_INVALID )
            progress_text = progress_text_str;
        
        //
        // Value
        //
        string progress_value_str = llJsonGetValue( str, [ "value" ] );
        if( progress_value_str != JSON_INVALID )
            progress_value = (integer)progress_value_str;

        //
        // Marquee animation
        //
        string progress_marquee_str = llJsonGetValue( str, [ "marquee" ] );
        if( progress_marquee_str != JSON_INVALID )
            progress_marquee = (integer)progress_marquee_str;
        
        //
        // Colour
        //
        string progress_color_str = llJsonGetValue( str, [ "color" ] );
        if( progress_color_str != JSON_INVALID )
            progress_color = (vector)progress_color_str;

        //
        // Auto-update
        //
        string auto_update_str = llJsonGetValue( str, [ "auto_update" ] );
        if( auto_update_str != JSON_INVALID )
            auto_update = (integer)auto_update_str;
        
        //
        // Check marquee setting and update marquee as appropriate.
        //
        if( progress_marquee )
        {
            progress_marquee_state = 0;
            llSetTimerEvent( 0.1 );
        }
        else
        {
            llSetTimerEvent( 0.0 );
        }

        //
        // If we are allowed to update, do so.
        //
        // This can be either through the auto-update feature, or by specifying
        // the "update" parameter with its value set to 1.
        //
        if( auto_update || (integer)llJsonGetValue( str, [ "update" ] ) )
            update_progress();
    }

    timer()
    {
        progress_marquee_state++;

        //
        // Note we account for the 20 blocks + the 4-block trail in this
        // conditional which is what state 24 is.
        //
        if( progress_marquee_state == 24 )
            progress_marquee_state = 0;

        update_progress();
    }
}