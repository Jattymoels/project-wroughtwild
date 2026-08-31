#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "WroughtwildCharacter.generated.h"

class UCameraComponent;
class UGridPlacementComponent;
class USpringArmComponent;
class UStaticMeshComponent;
class UWroughtwildInventoryComponent;

// Spike pawn: a controllable capsule with third-person camera, resource
// harvesting and grid build mode. Mouse and keyboard only (D-008).
UCLASS()
class WROUGHTWILD_API AWroughtwildCharacter : public ACharacter
{
	GENERATED_BODY()

public:
	AWroughtwildCharacter();

	virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

	UPROPERTY(VisibleAnywhere, Category = "Wroughtwild")
	TObjectPtr<UWroughtwildInventoryComponent> Inventory;

	UPROPERTY(VisibleAnywhere, Category = "Wroughtwild")
	TObjectPtr<UGridPlacementComponent> Placement;

protected:
	UPROPERTY(VisibleAnywhere, Category = "Wroughtwild")
	TObjectPtr<UStaticMeshComponent> BodyMesh;

	UPROPERTY(VisibleAnywhere, Category = "Wroughtwild")
	TObjectPtr<USpringArmComponent> CameraBoom;

	UPROPERTY(VisibleAnywhere, Category = "Wroughtwild")
	TObjectPtr<UCameraComponent> Camera;

	// Tunable: harvesting pace and how close the player must stand.
	UPROPERTY(EditAnywhere, Category = "Wroughtwild")
	float InteractRange = 350.0f;

	void MoveForward(float Value);
	void MoveRight(float Value);
	void Interact();
	void ToggleBuildMode();
	void PrimaryAction();
	void RemoveBlock();
	void RotatePreview();
};
