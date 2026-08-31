#include "PlacedBlock.h"

#include "Components/StaticMeshComponent.h"
#include "UObject/ConstructorHelpers.h"

namespace
{
	// The engine cube asset is 100 units on each side.
	constexpr float BasicCubeSize = 100.0f;
}

APlacedBlock::APlacedBlock()
{
	PrimaryActorTick.bCanEverTick = false;

	Mesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh"));
	SetRootComponent(Mesh);

	static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(
		TEXT("/Engine/BasicShapes/Cube.Cube"));
	if (CubeMesh.Succeeded())
	{
		Mesh->SetStaticMesh(CubeMesh.Object);
	}
	Mesh->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	Mesh->SetCollisionResponseToAllChannels(ECR_Block);
	Mesh->SetMobility(EComponentMobility::Movable);
}

void APlacedBlock::InitializeBlock(FName InFamily, int32 InCost, float GridSize)
{
	MaterialFamily = InFamily;
	MaterialCost = InCost;
	Mesh->SetWorldScale3D(FVector(GridSize / BasicCubeSize));
}
