#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "PlacedBlock.generated.h"

class UStaticMeshComponent;

// A player-placed construction block occupying one grid cell.
UCLASS()
class WROUGHTWILD_API APlacedBlock : public AActor
{
	GENERATED_BODY()

public:
	APlacedBlock();

	// Family the block was paid with, refunded (partially) on removal.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Wroughtwild|Construction")
	FName MaterialFamily = TEXT("wood");

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Wroughtwild|Construction")
	int32 MaterialCost = 1;

	void InitializeBlock(FName InFamily, int32 InCost, float GridSize);

protected:
	UPROPERTY(VisibleAnywhere, Category = "Wroughtwild|Construction")
	TObjectPtr<UStaticMeshComponent> Mesh;
};
