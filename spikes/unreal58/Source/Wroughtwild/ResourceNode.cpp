#include "ResourceNode.h"

#include "Components/StaticMeshComponent.h"
#include "UObject/ConstructorHelpers.h"

AResourceNode::AResourceNode()
{
	PrimaryActorTick.bCanEverTick = false;

	Mesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh"));
	SetRootComponent(Mesh);

	static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderMesh(
		TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
	if (CylinderMesh.Succeeded())
	{
		Mesh->SetStaticMesh(CylinderMesh.Object);
	}
}

int32 AResourceNode::Harvest()
{
	if (RemainingUnits <= 0)
	{
		return 0;
	}

	const int32 Granted = FMath::Min(UnitsPerHarvest, RemainingUnits);
	RemainingUnits -= Granted;

	if (RemainingUnits <= 0)
	{
		Destroy();
	}
	return Granted;
}
