#include "GridPlacementComponent.h"

#include "Components/StaticMeshComponent.h"
#include "Engine/World.h"
#include "GameFramework/Actor.h"
#include "GameFramework/Controller.h"
#include "GameFramework/Pawn.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "PlacedBlock.h"
#include "UObject/ConstructorHelpers.h"
#include "WroughtwildGrid.h"
#include "WroughtwildInventoryComponent.h"

namespace
{
	constexpr float BasicCubeSize = 100.0f;
	const FLinearColor ValidColor(0.1f, 0.9f, 0.2f, 0.5f);
	const FLinearColor InvalidColor(0.9f, 0.1f, 0.1f, 0.5f);
}

UGridPlacementComponent::UGridPlacementComponent()
{
	PrimaryComponentTick.bCanEverTick = true;
}

void UGridPlacementComponent::BeginPlay()
{
	Super::BeginPlay();
	CreatePreviewMesh();
}

void UGridPlacementComponent::CreatePreviewMesh()
{
	AActor* Owner = GetOwner();
	if (!Owner)
	{
		return;
	}

	PreviewMesh = NewObject<UStaticMeshComponent>(Owner, TEXT("PlacementPreview"));
	PreviewMesh->RegisterComponent();
	PreviewMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	PreviewMesh->SetCastShadow(false);
	PreviewMesh->SetVisibility(false);
	PreviewMesh->SetWorldScale3D(FVector(GridSize / BasicCubeSize));

	UStaticMesh* CubeMesh = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cube.Cube"));
	if (CubeMesh)
	{
		PreviewMesh->SetStaticMesh(CubeMesh);
	}

	UMaterialInterface* BaseMaterial =
		LoadObject<UMaterialInterface>(nullptr, TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
	if (BaseMaterial)
	{
		PreviewMaterial = UMaterialInstanceDynamic::Create(BaseMaterial, this);
		PreviewMesh->SetMaterial(0, PreviewMaterial);
	}
}

void UGridPlacementComponent::SetBuildModeEnabled(bool bEnabled)
{
	bBuildModeEnabled = bEnabled;
	if (!bBuildModeEnabled && PreviewMesh)
	{
		PreviewMesh->SetVisibility(false);
		bPreviewVisible = false;
	}
}

bool UGridPlacementComponent::GetViewTrace(FHitResult& OutHit) const
{
	const APawn* Pawn = Cast<APawn>(GetOwner());
	if (!Pawn || !Pawn->GetController())
	{
		return false;
	}

	FVector ViewLocation;
	FRotator ViewRotation;
	Pawn->GetController()->GetPlayerViewPoint(ViewLocation, ViewRotation);

	FCollisionQueryParams Params(SCENE_QUERY_STAT(WroughtwildPlacement), false, GetOwner());
	return GetWorld()->LineTraceSingleByChannel(
		OutHit,
		ViewLocation,
		ViewLocation + ViewRotation.Vector() * PlacementRange,
		ECC_Visibility,
		Params);
}

bool UGridPlacementComponent::IsCellFree(const FVector& CellCenter) const
{
	// Slightly smaller than the cell so face-adjacent neighbours don't collide.
	const FVector BoxExtent(GridSize * 0.5f - 2.0f);
	FCollisionQueryParams Params(SCENE_QUERY_STAT(WroughtwildCellFree), false, GetOwner());
	return !GetWorld()->OverlapBlockingTestByChannel(
		CellCenter,
		FQuat::Identity,
		ECC_WorldStatic,
		FCollisionShape::MakeBox(BoxExtent),
		Params);
}

UWroughtwildInventoryComponent* UGridPlacementComponent::FindInventory() const
{
	return GetOwner() ? GetOwner()->FindComponentByClass<UWroughtwildInventoryComponent>() : nullptr;
}

void UGridPlacementComponent::UpdatePreview()
{
	if (!PreviewMesh)
	{
		return;
	}

	FHitResult Hit;
	if (!GetViewTrace(Hit))
	{
		PreviewMesh->SetVisibility(false);
		bPreviewVisible = false;
		bPreviewValid = false;
		return;
	}

	PreviewLocation = WroughtwildGrid::PlacementCellCenter(Hit.ImpactPoint, Hit.ImpactNormal, GridSize);

	const UWroughtwildInventoryComponent* Inventory = FindInventory();
	const bool bAffordable =
		Inventory && Inventory->GetCount(SelectedMaterialFamily) >= MaterialCostPerBlock;
	bPreviewValid = bAffordable && IsCellFree(PreviewLocation);

	PreviewMesh->SetWorldLocationAndRotation(PreviewLocation, PreviewRotation);
	PreviewMesh->SetVisibility(true);
	bPreviewVisible = true;

	if (PreviewMaterial)
	{
		PreviewMaterial->SetVectorParameterValue(TEXT("Color"), bPreviewValid ? ValidColor : InvalidColor);
	}
}

void UGridPlacementComponent::TickComponent(float DeltaTime, ELevelTick TickType,
	FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
	if (bBuildModeEnabled)
	{
		UpdatePreview();
	}
}

bool UGridPlacementComponent::TryPlaceBlock()
{
	if (!bBuildModeEnabled || !bPreviewVisible || !bPreviewValid)
	{
		return false;
	}

	UWroughtwildInventoryComponent* Inventory = FindInventory();
	if (!Inventory || !Inventory->ConsumeMaterial(SelectedMaterialFamily, MaterialCostPerBlock))
	{
		return false;
	}

	FActorSpawnParameters SpawnParams;
	SpawnParams.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	APlacedBlock* Block = GetWorld()->SpawnActor<APlacedBlock>(
		APlacedBlock::StaticClass(), PreviewLocation, PreviewRotation, SpawnParams);
	if (!Block)
	{
		Inventory->AddMaterial(SelectedMaterialFamily, MaterialCostPerBlock);
		return false;
	}

	Block->InitializeBlock(SelectedMaterialFamily, MaterialCostPerBlock, GridSize);
	return true;
}

bool UGridPlacementComponent::TryRemoveBlock()
{
	if (!bBuildModeEnabled)
	{
		return false;
	}

	FHitResult Hit;
	if (!GetViewTrace(Hit))
	{
		return false;
	}

	APlacedBlock* Block = Cast<APlacedBlock>(Hit.GetActor());
	if (!Block)
	{
		return false;
	}

	if (UWroughtwildInventoryComponent* Inventory = FindInventory())
	{
		const int32 Refund = FMath::FloorToInt32(Block->MaterialCost * RemovalRefundFraction);
		Inventory->AddMaterial(Block->MaterialFamily, Refund);
	}
	Block->Destroy();
	return true;
}

void UGridPlacementComponent::RotatePreview()
{
	PreviewRotation.Yaw = FMath::Fmod(PreviewRotation.Yaw + 90.0f, 360.0f);
}
