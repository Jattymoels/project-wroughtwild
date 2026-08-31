#include "WroughtwildInventoryComponent.h"

int32 UWroughtwildInventoryComponent::GetCount(FName MaterialFamily) const
{
	const int32* Count = MaterialCounts.Find(MaterialFamily);
	return Count ? *Count : 0;
}

void UWroughtwildInventoryComponent::AddMaterial(FName MaterialFamily, int32 Amount)
{
	if (Amount <= 0)
	{
		return;
	}
	MaterialCounts.FindOrAdd(MaterialFamily) += Amount;
}

bool UWroughtwildInventoryComponent::ConsumeMaterial(FName MaterialFamily, int32 Amount)
{
	int32* Count = MaterialCounts.Find(MaterialFamily);
	if (!Count || *Count < Amount)
	{
		return false;
	}
	*Count -= Amount;
	return true;
}
