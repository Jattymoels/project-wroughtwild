#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "ResourceNode.generated.h"

class UStaticMeshComponent;

// A harvestable world resource (wood or iron in the slice). Depletes and
// destroys itself; a respawn policy is a later design question, not spiked.
UCLASS()
class WROUGHTWILD_API AResourceNode : public AActor
{
	GENERATED_BODY()

public:
	AResourceNode();

	// Material family granted per harvest, matching data/tuning ids
	// (e.g. "wood", "iron_ore").
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Wroughtwild|Resource")
	FName MaterialFamily = TEXT("wood");

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Wroughtwild|Resource")
	int32 RemainingUnits = 20;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Wroughtwild|Resource")
	int32 UnitsPerHarvest = 2;

	// Returns the units actually granted (0 when depleted).
	UFUNCTION(BlueprintCallable, Category = "Wroughtwild|Resource")
	int32 Harvest();

protected:
	UPROPERTY(VisibleAnywhere, Category = "Wroughtwild|Resource")
	TObjectPtr<UStaticMeshComponent> Mesh;
};
