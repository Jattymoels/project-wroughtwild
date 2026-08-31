#include "WroughtwildTuningSubsystem.h"

#include "Dom/JsonObject.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"

DEFINE_LOG_CATEGORY_STATIC(LogWroughtwildTuning, Log, All);

void UWroughtwildTuningSubsystem::Initialize(FSubsystemCollectionBase& Collection)
{
	Super::Initialize(Collection);
	LoadCraftingTuning();
}

FString UWroughtwildTuningSubsystem::GetTuningDirectory()
{
	return FPaths::ConvertRelativePathToFull(
		FPaths::Combine(FPaths::ProjectDir(), TEXT("../../data/tuning")));
}

bool UWroughtwildTuningSubsystem::LoadCraftingTuning()
{
	bLoaded = false;

	const FString Path = FPaths::Combine(GetTuningDirectory(), TEXT("crafting.json"));
	FString Content;
	if (!FFileHelper::LoadFileToString(Content, *Path))
	{
		UE_LOG(LogWroughtwildTuning, Warning, TEXT("Cannot read tuning file: %s"), *Path);
		return false;
	}

	TSharedPtr<FJsonObject> Root;
	const TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(Content);
	if (!FJsonSerializer::Deserialize(Reader, Root) || !Root.IsValid())
	{
		UE_LOG(LogWroughtwildTuning, Warning, TEXT("Invalid JSON in tuning file: %s"), *Path);
		return false;
	}

	const TArray<TSharedPtr<FJsonValue>>* Recipes = nullptr;
	double Salvage = 0.0;
	if (!Root->TryGetArrayField(TEXT("recipes"), Recipes) ||
		!Root->TryGetNumberField(TEXT("salvage_return_fraction"), Salvage))
	{
		UE_LOG(LogWroughtwildTuning, Warning, TEXT("Missing expected fields in %s"), *Path);
		return false;
	}

	RecipeCount = Recipes->Num();
	SalvageReturnFraction = static_cast<float>(Salvage);
	bLoaded = true;
	UE_LOG(LogWroughtwildTuning, Log, TEXT("Loaded crafting tuning: %d recipes"), RecipeCount);
	return true;
}
