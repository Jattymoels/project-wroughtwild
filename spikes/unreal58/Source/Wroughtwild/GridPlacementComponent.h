#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "GridPlacementComponent.generated.h"

class APlacedBlock;
class UMaterialInstanceDynamic;
class UStaticMeshComponent;
class UWroughtwildInventoryComponent;

// Grid snap-placement with a validity-coloured preview: the core interaction
// the ADR-0001 spike must demonstrate. Owned by the player character; traces
// from the view, snaps to the placement cell and previews valid (green) or
// invalid (red) placement before spending any material.
UCLASS(ClassGroup = (Wroughtwild), meta = (BlueprintSpawnableComponent))
class WROUGHTWILD_API UGridPlacementComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UGridPlacementComponent();

	// Tunable: balance between Minecraft-like constraint and detail
	// (construction spec, "Grid size"). Final value is an open question.
	UPROPERTY(EditAnywhere, Category = "Wroughtwild|Construction")
	float GridSize = 100.0f;

	// Tunable: building pace and need for scaffolding ("Placement range").
	UPROPERTY(EditAnywhere, Category = "Wroughtwild|Construction")
	float PlacementRange = 600.0f;

	// Tunable: experimentation freedom versus commitment ("Removal refund").
	// Mirrors salvage_return_fraction in data/tuning/crafting.json.
	UPROPERTY(EditAnywhere, Category = "Wroughtwild|Construction")
	float RemovalRefundFraction = 0.5f;

	UPROPERTY(EditAnywhere, Category = "Wroughtwild|Construction")
	FName SelectedMaterialFamily = TEXT("wood");

	UPROPERTY(EditAnywhere, Category = "Wroughtwild|Construction")
	int32 MaterialCostPerBlock = 1;

	UFUNCTION(BlueprintCallable, Category = "Wroughtwild|Construction")
	void SetBuildModeEnabled(bool bEnabled);

	UFUNCTION(BlueprintCallable, Category = "Wroughtwild|Construction")
	bool IsBuildModeEnabled() const { return bBuildModeEnabled; }

	// Places a block at the current preview cell when the preview is valid.
	UFUNCTION(BlueprintCallable, Category = "Wroughtwild|Construction")
	bool TryPlaceBlock();

	// Removes an aimed-at placed block, refunding part of its material.
	UFUNCTION(BlueprintCallable, Category = "Wroughtwild|Construction")
	bool TryRemoveBlock();

	UFUNCTION(BlueprintCallable, Category = "Wroughtwild|Construction")
	void RotatePreview();

	virtual void TickComponent(float DeltaTime, ELevelTick TickType,
		FActorComponentTickFunction* ThisTickFunction) override;

protected:
	virtual void BeginPlay() override;

private:
	bool bBuildModeEnabled = false;
	bool bPreviewValid = false;
	bool bPreviewVisible = false;
	FVector PreviewLocation = FVector::ZeroVector;
	FRotator PreviewRotation = FRotator::ZeroRotator;

	UPROPERTY()
	TObjectPtr<UStaticMeshComponent> PreviewMesh;

	UPROPERTY()
	TObjectPtr<UMaterialInstanceDynamic> PreviewMaterial;

	bool GetViewTrace(FHitResult& OutHit) const;
	bool IsCellFree(const FVector& CellCenter) const;
	UWroughtwildInventoryComponent* FindInventory() const;
	void UpdatePreview();
	void CreatePreviewMesh();
};
