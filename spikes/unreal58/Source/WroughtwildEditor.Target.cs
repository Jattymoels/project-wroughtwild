using UnrealBuildTool;
using System.Collections.Generic;

public class WroughtwildEditorTarget : TargetRules
{
	public WroughtwildEditorTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		DefaultBuildSettings = BuildSettingsVersion.Latest;
		IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
		ExtraModuleNames.Add("Wroughtwild");
	}
}
