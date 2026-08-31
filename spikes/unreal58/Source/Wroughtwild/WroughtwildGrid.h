#pragma once

#include "CoreMinimal.h"

// Grid snapping used by placement preview and automation tests. Kept as free
// functions so rules stay testable without a world (see AGENTS.md: separate
// simulation rules from presentation).
namespace WroughtwildGrid
{
	// Snaps a world position to the centre of its grid cell.
	inline FVector SnapToCellCenter(const FVector& Location, float GridSize)
	{
		const FVector Cell(
			FMath::FloorToFloat(Location.X / GridSize),
			FMath::FloorToFloat(Location.Y / GridSize),
			FMath::FloorToFloat(Location.Z / GridSize));
		return Cell * GridSize + FVector(GridSize * 0.5f);
	}

	// Cell the placement targets: the hit surface pushed slightly along its
	// normal so building against a face lands in the adjacent cell.
	inline FVector PlacementCellCenter(const FVector& ImpactPoint, const FVector& ImpactNormal, float GridSize)
	{
		return SnapToCellCenter(ImpactPoint + ImpactNormal * (GridSize * 0.25f), GridSize);
	}
}
