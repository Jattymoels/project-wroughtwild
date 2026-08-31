#include "WroughtwildCharacter.h"

#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "Components/StaticMeshComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/Controller.h"
#include "GameFramework/SpringArmComponent.h"
#include "GridPlacementComponent.h"
#include "ResourceNode.h"
#include "UObject/ConstructorHelpers.h"
#include "WroughtwildInventoryComponent.h"

AWroughtwildCharacter::AWroughtwildCharacter()
{
	PrimaryActorTick.bCanEverTick = false;

	GetCapsuleComponent()->InitCapsuleSize(42.0f, 96.0f);

	BodyMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BodyMesh"));
	BodyMesh->SetupAttachment(GetCapsuleComponent());
	BodyMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	static ConstructorHelpers::FObjectFinder<UStaticMesh> CapsuleMesh(
		TEXT("/Engine/BasicShapes/Capsule.Capsule"));
	if (CapsuleMesh.Succeeded())
	{
		BodyMesh->SetStaticMesh(CapsuleMesh.Object);
		BodyMesh->SetRelativeScale3D(FVector(0.84f, 0.84f, 1.92f));
	}

	CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
	CameraBoom->SetupAttachment(RootComponent);
	CameraBoom->TargetArmLength = 450.0f;
	CameraBoom->bUsePawnControlRotation = true;

	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
	Camera->bUsePawnControlRotation = false;

	Inventory = CreateDefaultSubobject<UWroughtwildInventoryComponent>(TEXT("Inventory"));
	Placement = CreateDefaultSubobject<UGridPlacementComponent>(TEXT("Placement"));

	bUseControllerRotationYaw = true;
	GetCharacterMovement()->MaxWalkSpeed = 500.0f;
}

void AWroughtwildCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

	PlayerInputComponent->BindAxis("MoveForward", this, &AWroughtwildCharacter::MoveForward);
	PlayerInputComponent->BindAxis("MoveRight", this, &AWroughtwildCharacter::MoveRight);
	PlayerInputComponent->BindAxis("Turn", this, &APawn::AddControllerYawInput);
	PlayerInputComponent->BindAxis("LookUp", this, &APawn::AddControllerPitchInput);

	PlayerInputComponent->BindAction("Jump", IE_Pressed, this, &ACharacter::Jump);
	PlayerInputComponent->BindAction("Jump", IE_Released, this, &ACharacter::StopJumping);
	PlayerInputComponent->BindAction("Interact", IE_Pressed, this, &AWroughtwildCharacter::Interact);
	PlayerInputComponent->BindAction("ToggleBuildMode", IE_Pressed, this, &AWroughtwildCharacter::ToggleBuildMode);
	PlayerInputComponent->BindAction("PrimaryAction", IE_Pressed, this, &AWroughtwildCharacter::PrimaryAction);
	PlayerInputComponent->BindAction("RemoveBlock", IE_Pressed, this, &AWroughtwildCharacter::RemoveBlock);
	PlayerInputComponent->BindAction("RotatePreview", IE_Pressed, this, &AWroughtwildCharacter::RotatePreview);
}

void AWroughtwildCharacter::MoveForward(float Value)
{
	if (Controller && Value != 0.0f)
	{
		const FRotator YawRotation(0.0f, Controller->GetControlRotation().Yaw, 0.0f);
		AddMovementInput(FRotationMatrix(YawRotation).GetUnitAxis(EAxis::X), Value);
	}
}

void AWroughtwildCharacter::MoveRight(float Value)
{
	if (Controller && Value != 0.0f)
	{
		const FRotator YawRotation(0.0f, Controller->GetControlRotation().Yaw, 0.0f);
		AddMovementInput(FRotationMatrix(YawRotation).GetUnitAxis(EAxis::Y), Value);
	}
}

void AWroughtwildCharacter::Interact()
{
	FVector ViewLocation;
	FRotator ViewRotation;
	GetController()->GetPlayerViewPoint(ViewLocation, ViewRotation);

	FHitResult Hit;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(WroughtwildInteract), false, this);
	if (!GetWorld()->LineTraceSingleByChannel(
			Hit, ViewLocation, ViewLocation + ViewRotation.Vector() * InteractRange,
			ECC_Visibility, Params))
	{
		return;
	}

	if (AResourceNode* Node = Cast<AResourceNode>(Hit.GetActor()))
	{
		const FName Family = Node->MaterialFamily;
		const int32 Granted = Node->Harvest();
		if (Granted > 0)
		{
			Inventory->AddMaterial(Family, Granted);
		}
	}
}

void AWroughtwildCharacter::ToggleBuildMode()
{
	Placement->SetBuildModeEnabled(!Placement->IsBuildModeEnabled());
}

void AWroughtwildCharacter::PrimaryAction()
{
	if (Placement->IsBuildModeEnabled())
	{
		Placement->TryPlaceBlock();
	}
	else
	{
		Interact();
	}
}

void AWroughtwildCharacter::RemoveBlock()
{
	Placement->TryRemoveBlock();
}

void AWroughtwildCharacter::RotatePreview()
{
	Placement->RotatePreview();
}
