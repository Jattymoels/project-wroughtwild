// The "one automated check" the ADR-0001 spike requires. Run from the editor:
// Tools > Test Automation > filter "Wroughtwild", or via MCP's automation
// toolset. Headless: -ExecCmds="Automation RunTests Wroughtwild" -unattended.

#include "Misc/AutomationTest.h"

#if WITH_AUTOMATION_TESTS

#include "Dom/JsonObject.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"
#include "WroughtwildGrid.h"
#include "WroughtwildTuningSubsystem.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FWroughtwildGridSnapTest,
	"Wroughtwild.Grid.SnapToCellCenter",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FWroughtwildGridSnapTest::RunTest(const FString& Parameters)
{
	const float Grid = 100.0f;

	// Any point inside a cell snaps to that cell's centre.
	TestEqual(TEXT("origin cell"),
		WroughtwildGrid::SnapToCellCenter(FVector(10, 20, 30), Grid), FVector(50, 50, 50));
	TestEqual(TEXT("negative coordinates"),
		WroughtwildGrid::SnapToCellCenter(FVector(-10, -170, 0), Grid), FVector(-50, -150, 50));
	TestEqual(TEXT("snapping is idempotent"),
		WroughtwildGrid::SnapToCellCenter(FVector(50, 50, 50), Grid), FVector(50, 50, 50));

	// Placing against the top face of a block lands in the cell above it.
	const FVector OnTopFace(50, 50, 100);
	TestEqual(TEXT("face placement selects adjacent cell"),
		WroughtwildGrid::PlacementCellCenter(OnTopFace, FVector::UpVector, Grid),
		FVector(50, 50, 150));

	return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FWroughtwildTuningLoadTest,
	"Wroughtwild.Tuning.CraftingJsonLoads",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FWroughtwildTuningLoadTest::RunTest(const FString& Parameters)
{
	const FString Path =
		FPaths::Combine(UWroughtwildTuningSubsystem::GetTuningDirectory(), TEXT("crafting.json"));

	FString Content;
	if (!TestTrue(TEXT("crafting.json is readable from the repo checkout"),
			FFileHelper::LoadFileToString(Content, *Path)))
	{
		return false;
	}

	TSharedPtr<FJsonObject> Root;
	const TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(Content);
	if (!TestTrue(TEXT("crafting.json parses"),
			FJsonSerializer::Deserialize(Reader, Root) && Root.IsValid()))
	{
		return false;
	}

	const TArray<TSharedPtr<FJsonValue>>* Recipes = nullptr;
	TestTrue(TEXT("recipes array present"), Root->TryGetArrayField(TEXT("recipes"), Recipes));
	if (Recipes)
	{
		bool bFoundFittings = false;
		for (const TSharedPtr<FJsonValue>& Value : *Recipes)
		{
			const TSharedPtr<FJsonObject>* Recipe;
			if (Value->TryGetObject(Recipe) &&
				(*Recipe)->GetStringField(TEXT("id")) == TEXT("iron_fittings"))
			{
				bFoundFittings = true;
			}
		}
		TestTrue(TEXT("iron_fittings recipe exists"), bFoundFittings);
	}

	return true;
}

#endif // WITH_AUTOMATION_TESTS
