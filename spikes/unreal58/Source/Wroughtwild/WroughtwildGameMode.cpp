#include "WroughtwildGameMode.h"

#include "WroughtwildCharacter.h"

AWroughtwildGameMode::AWroughtwildGameMode()
{
	DefaultPawnClass = AWroughtwildCharacter::StaticClass();
}
