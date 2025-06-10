Subasta de Contrato Inteligente
Este repositorio contiene un contrato inteligente de subasta desarrollado en Solidity. Este contrato permite a los usuarios pujar por un artículo virtual o un activo, con características como la extensión automática de la subasta, un incremento mínimo de puja, y un mecanismo de reembolso para los no ganadores.

Contenido
Características
Despliegue
Uso
Estados de la Subasta
Pujas
Finalización de la Subasta
Reembolsos y Retiros Parciales
Eventos
Modificadores
Variables de Estado Clave
Consideraciones de Seguridad
Licencia
Características
Pujas Dinámicas: Los participantes pueden realizar pujas, que deben ser al menos un 5% más altas que la puja actual más alta.
Extensión de la Subasta: Si se realiza una puja en los últimos 10 minutos de la subasta, la duración de la misma se extiende por 10 minutos adicionales para permitir contraofertas.
Comisión por Gas: Se aplica una comisión del 2% sobre los depósitos al realizar los reembolsos.
Control del Propietario: Solo el propietario del contrato puede iniciar los reembolsos para los no ganadores.
Retiros Parciales: Los participantes pueden retirar el exceso de Ether que hayan depositado por encima de su última puja válida antes de que la subasta termine.
Visualización de Pujas: Permite ver todas las pujas realizadas y sus respectivos montos.
Consulta del Ganador: Una vez finalizada la subasta, se puede consultar el ganador y el monto de la puja ganadora.
Despliegue
Para desplegar este contrato, necesitarás un entorno de desarrollo de Solidity (como Remix, Hardhat o Truffle) y una red Ethereum (o una red de prueba).

Compilación: Compila el contrato Auction.sol usando la versión ^0.8.20 de Solidity.
Despliegue: Despliega el contrato, proporcionando la duración de la subasta en minutos como parámetro en el constructor:
Solidity

constructor(uint256 _durationInMinutes)
Por ejemplo, para una subasta de 60 minutos, el parámetro sería 60.
Uso
Estados de la Subasta
El contrato tiene tres estados principales:

Activa: La subasta está en curso y se pueden realizar pujas.
Pendiente de Finalización: El tiempo de la subasta ha expirado, pero la función endAuction() aún no ha sido llamada.
Finalizada: La subasta ha sido oficialmente terminada y el ganador ha sido declarado.
Pujas
Para realizar una puja, llama a la función bid() y envía Ether con la transacción (msg.value).
La primera puja debe ser al menos 1 wei.
Las pujas subsiguientes deben ser al menos un 5% más altas que la puja actual más alta.
Si tu puja es más alta que la puja actual y la subasta está en sus últimos 10 minutos, el tiempo de la subasta se extenderá.
Finalización de la Subasta
Una vez que el auctionEndTime ha pasado, cualquier persona puede llamar a la función endAuction() para finalizar formalmente la subasta.
Esto emitirá el evento AuctionEnded con la información del ganador.
Después de llamar a endAuction(), puedes usar showWinner() para ver quién ganó y por cuánto.
Reembolsos y Retiros Parciales
Retiros Parciales: Los participantes pueden retirar el exceso de Ether que hayan depositado (es decir, el monto total depositado menos su última puja válida) llamando a partialWithdrawal() mientras la subasta esté activa. Esto es útil si un usuario accidentalmente envió más Ether del necesario para su puja.
Reembolsos: Después de que la subasta haya terminado (es decir, endAuction() ha sido llamada), el propietario del contrato puede llamar a returnDeposits(). Esta función iterará sobre todos los participantes no ganadores y les reembolsará su Ether depositado, deduciendo una comisión del 2%.
Eventos
El contrato emite los siguientes eventos para facilitar el seguimiento de la actividad:

NewBid(address indexed bidder, uint256 amount): Se emite cuando se realiza una nueva puja.
AuctionEnded(address winner, uint256 winningBid): Se emite cuando la subasta ha terminado.
DepositRefunded(address indexed beneficiary, uint256 amount): Se emite cuando se devuelve un depósito a un participante no ganador.
PartialWithdrawal(address indexed bidder, uint256 amount): Se emite cuando un participante realiza un retiro parcial de sus fondos.
AuctionExtended(uint256 newEndTime): Se emite cuando la duración de la subasta se extiende.
Modificadores
onlyOwner: Restringe el acceso a la función solo al propietario del contrato.
auctionActive: Restringe el acceso a la función solo si la subasta está activa.
auctionEnded: Restringe el acceso a la función solo si la subasta ha terminado.
Variables de Estado Clave
owner: Dirección del propietario del contrato.
auctionStartTime: Marca de tiempo de inicio de la subasta.
auctionEndTime: Marca de tiempo de finalización de la subasta.
highestBid: El monto de la puja más alta actual.
highestBidder: La dirección del postor con la puja más alta.
ended: Un booleano que indica si la subasta ha terminado.
deposits: Un mapeo de las direcciones de los participantes a la cantidad total de Ether que han depositado.
lastBids: Un mapeo de las direcciones de los participantes a su última puja válida.
allBidders: Un array de todas las direcciones que han pujado en la subasta.
Consideraciones de Seguridad
Reentrancy: El contrato utiliza el patrón "Checks-Effects-Interactions" y resetea los saldos antes de las transferencias para mitigar los ataques de reentrada, especialmente en las funciones returnDeposits() y partialWithdrawal().
Validaciones: Se incluyen validaciones para asegurar que las pujas cumplen con los requisitos mínimos y que las funciones se llaman en el estado correcto de la subasta.
Licencia
Este proyecto está bajo la licencia MIT. Consulta el archivo LICENSE para más detalles.

