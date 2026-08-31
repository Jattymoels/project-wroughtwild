#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "WroughtwildInventoryComponent.generated.h"

// Stores harvested materials by family (construction spec core rule 1:
// "a harvested material is stored as a family, not as every possible
// placeable geometry").
UCLASS(ClassGroup = (Wroughtwild), meta = (BlueprintSpawnableComponent))
class WROUGHTWILD_API UWroughtwildInventoryComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "Wroughtwild|Inventory")
	int32 GetCount(FName MaterialFamily) const;

	UFUNCTION(BlueprintCallable, Category = "Wroughtwild|Inventory")
	void AddMaterial(FName MaterialFamily, int32 Amount);

	// Returns false (and consumes nothing) when fewer than Amount are held.
	UFUNCTION(BlueprintCallable, Category = "Wroughtwild|Inventory")
	bool ConsumeMaterial(FName MaterialFamily, int32 Amount);

private:
	UPROPERTY(VisibleAnywhere, Category = "Wroughtwild|Inventory")
	TMap<FName, int32> MaterialCounts;
};
