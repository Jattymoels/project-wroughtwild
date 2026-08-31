#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "WroughtwildTuningSubsystem.generated.h"

// Loads the engine-neutral tuning files from data/tuning at startup, proving
// the "core tuning values are externalised from game logic" acceptance
// criterion inside Unreal. Only the values the spike needs are exposed.
UCLASS()
class WROUGHTWILD_API UWroughtwildTuningSubsystem : public UGameInstanceSubsystem
{
	GENERATED_BODY()

public:
	virtual void Initialize(FSubsystemCollectionBase& Collection) override;

	// Resolves the repository's data/tuning directory. The spike project lives
	// at spikes/unreal58/, so tuning sits two levels above the project root.
	static FString GetTuningDirectory();

	// Parses crafting.json; returns false (and logs) when missing or invalid.
	bool LoadCraftingTuning();

	UFUNCTION(BlueprintCallable, Category = "Wroughtwild|Tuning")
	bool IsTuningLoaded() const { return bLoaded; }

	UFUNCTION(BlueprintCallable, Category = "Wroughtwild|Tuning")
	int32 GetRecipeCount() const { return RecipeCount; }

	UFUNCTION(BlueprintCallable, Category = "Wroughtwild|Tuning")
	float GetSalvageReturnFraction() const { return SalvageReturnFraction; }

private:
	bool bLoaded = false;
	int32 RecipeCount = 0;
	float SalvageReturnFraction = 0.0f;
};
