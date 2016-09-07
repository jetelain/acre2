/*
 * Author: ACRE2Team
 * SHORT DESCRIPTION
 *
 * Arguments:
 * 0: ARGUMENT ONE <TYPE>
 * 1: ARGUMENT TWO <TYPE>
 *
 * Return Value:
 * RETURN VALUE <TYPE>
 *
 * Example:
 * [ARGUMENTS] call acre_COMPONENT_fnc_FUNCTIONNAME
 *
 * Public: No
 */
#include "script_component.hpp"

private ["_volume", "_channelNumber", "_channelData", "_rxOnly"];
params["_radioId"];

_channelNumber = [_radioId, "getCurrentChannel"] call EFUNC(sys_data,dataEvent);
_channelData = [_radioId, _channelNumber] call FUNC(getChannelDataInternal);

_rxOnly = HASH_GET(_channelData, "rxOnly");
TRACE_3("RX ONLY", _radioId, _channelNumber, _rxOnly);
if(_rxOnly) exitWith {
    TRACE_1("EXITING RX ONLY", _rxOnly);
    false;
};

_volume = [_radioId, "getVolume"] call EFUNC(sys_data,dataEvent);
[_radioId, "Acre_GenericBeep", [0,0,0], [0,1,0], _volume] call EFUNC(sys_radio,playRadioSound);
SCRATCH_SET(_radioId, "PTTDown", true);
true;
