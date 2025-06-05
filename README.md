# ETHKipuAuctionW
Auction coded in Solidity
# Contrato Inteligente de Subasta Pública en Ethereum

---

## Descripción del Proyecto

Este repositorio contiene un contrato inteligente de subasta desarrollado en **Solidity**, diseñado para ejecutarse en la blockchain de Ethereum (o redes compatibles como Sepolia). El contrato permite a los participantes realizar ofertas por un activo (implícito, ya que no se gestiona el activo directamente en el contrato), gestiona el tiempo de la subasta, determina el ganador, y maneja los reembolsos de los fondos.

El objetivo principal de este proyecto es demostrar la implementación de una lógica de subasta robusta y segura, incluyendo mecanismos de extensión de tiempo, manejo de ofertas, y protección contra vulnerabilidades comunes como la reentrada.

---

## Características Principales

* **Subasta Basada en Tiempo:** La subasta tiene una duración predefinida y finaliza automáticamente al expirar el tiempo.
* **Ofertas Dinámicas:** Las ofertas deben ser al menos un 5% superiores a la oferta actual más alta.
* **Extensión de Plazo:** Si se realiza una oferta en los últimos 10 minutos de la subasta, el plazo se extiende 10 minutos adicionales para permitir contraofertas.
* **Gestión de Depósitos:** Los participantes depositan Ether al ofertar. Los fondos de los perdedores pueden ser reembolsados (con una pequeña comisión del 2%).
* **Retiro Parcial:** Los ofertantes pueden retirar cualquier exceso de Ether depositado que esté por encima de su última oferta válida mientras la subasta está activa.
* **Determinación del Ganador:** Una vez finalizada la subasta, se identifica claramente al ofertante con la oferta más alta.
* **Seguridad:** Implementación de patrones de seguridad para prevenir ataques comunes como la reentrada.
* **Eventos:** Comunicación clara del estado de la subasta a través de eventos en la blockchain.

---

## Despliegue del Contrato

 Entorno de desarrollo de Solidity 
 red Ethereum, Sepolia para pruebas

## Funciones del Contrato

* `constructor(uint256 _durationInMinutes)`:
    * **Propósito:** Inicializa el contrato al desplegarlo. Establece el `owner` (quien lo despliega), el `auctionStartTime` y el `auctionEndTime` basado en la duración provista.
    * **Parámetros:**
        * `_durationInMinutes`: La duración total de la subasta en minutos.

* `bid() public payable`:
    * **Propósito:** Permite a un participante realizar una oferta en la subasta. Envía Ether con la transacción (`msg.value`).
    * **Requisitos:** La subasta debe estar activa. La oferta debe ser al menos un 5% mayor que la oferta actual más alta (o 1 wei si es la primera oferta).
    * **Efectos:** Actualiza la `highestBid` y el `highestBidder` si la oferta es la más alta. Extiende el `auctionEndTime` si la oferta se realiza en los últimos 10 minutos. Emite el evento `NewBid`.

* `endAuction() public`:
    * **Propósito:** Marca la subasta como finalizada si el `auctionEndTime` ha expirado.
    * **Requisitos:** `block.timestamp` debe ser mayor o igual a `auctionEndTime` y la subasta no debe haber terminado ya.
    * **Efectos:** Emite el evento `AuctionEnded` con el ganador y la oferta final. Puede ser llamada por cualquier persona una vez que la subasta ha finalizado por tiempo.

* `showWinner() public view returns (address winner, uint256 winningBid)`:
    * **Propósito:** Retorna la dirección del ofertante ganador y el monto de la oferta ganadora.
    * **Requisitos:** La subasta debe haber finalizado.

* `showBids() public view returns (address[] memory bidders, uint256[] memory amounts)`:
    * **Propósito:** Retorna una lista de todas las direcciones que han ofertado y sus últimos montos ofertados.
    * **Utilidad:** Permite ver un historial de participantes y sus ofertas finales.

* `returnDeposits() public`:
    * **Propósito:** Permite a los participantes que no ganaron la subasta reclamar su Ether depositado.
    * **Requisitos:** La subasta debe haber finalizado y el llamador no debe ser el `highestBidder`.
    * **Efectos:** Calcula un reembolso del 98% del depósito (se retiene una comisión del 2% por el gas/plataforma) y transfiere el Ether de vuelta al llamador. Emite el evento `DepositRefunded`. Incluye protección contra ataques de reentrada.

* `partialWithdrawal() public`:
    * **Propósito:** Permite a un participante retirar cualquier cantidad de Ether que haya depositado por encima de su última oferta válida mientras la subasta está en curso.
    * **Requisitos:** La subasta debe estar activa y el llamador debe tener un depósito excedente.
    * **Efectos:** Transfiere el monto excedente de vuelta al llamador y ajusta su depósito al valor de su última oferta. Emite el evento `PartialWithdrawal`. Incluye protección contra ataques de reentrada.

---

## Variables de Estado

* `address public owner`: La dirección que desplegó el contrato.
* `uint256 public auctionStartTime`: El `timestamp` de Unix cuando la subasta comenzó.
* `uint256 public auctionEndTime`: El `timestamp` de Unix cuando la subasta está programada para finalizar.
* `uint256 public highestBid`: El monto de la oferta más alta actual.
* `address public highestBidder`: La dirección del ofertante con la oferta más alta actual.
* `bool public ended`: Un booleano que indica si la subasta ha terminado (`true`) o no (`false`).
* `mapping(address => uint256) public deposits`: Un mapeo que registra el total de Ether depositado por cada participante.
* `mapping(address => Bid) public lastBids`: Un mapeo que almacena la última oferta válida (dirección y monto) realizada por cada participante.
* `address[] public allBidders`: Un array que guarda todas las direcciones que han realizado al menos una oferta. Usado para la función `showBids()`.
* `mapping(address => bool) private hasBidder`: Un mapeo auxiliar para verificar rápidamente si una dirección ya está en `allBidders`, evitando duplicados.
* `uint256 public constant EXTENSION_TIME`: Tiempo en minutos (10 minutos) que se extiende la subasta si se realiza una oferta cerca del final.
* `uint256 public constant MIN_BID_INCREMENT_PERCENT`: El porcentaje mínimo (5%) en que una nueva oferta debe superar a la anterior.
* `uint256 public constant GAS_COMMISSION_PERCENT`: El porcentaje de comisión (2%) que se retiene de los depósitos reembolsados.

---

## Eventos

Los eventos son emitidos por el contrato para notificar a las aplicaciones externas (como interfaces de usuario o exploradores de bloques) sobre cambios importantes en el estado de la subasta.

* `event NewBid(address indexed bidder, uint256 amount)`:
    * Emitido cuando se realiza una nueva oferta válida.
    * `bidder`: La dirección del ofertante.
    * `amount`: El monto de la oferta.

* `event AuctionEnded(address winner, uint256 winningBid)`:
    * Emitido cuando la subasta ha finalizado y se ha determinado un ganador.
    * `winner`: La dirección del ofertante ganador.
    * `winningBid`: El monto de la oferta ganadora.

* `event DepositRefunded(address indexed beneficiary, uint256 amount)`:
    * Emitido cuando un participante no ganador reclama un reembolso de su depósito.
    * `beneficiary`: La dirección a la que se le reembolsa el Ether.
    * `amount`: El monto reembolsado.

* `event PartialWithdrawal(address indexed bidder, uint256 amount)`:
    * Emitido cuando un participante retira una parte de su depósito (el excedente sobre su última oferta).
    * `bidder`: La dirección que realiza el retiro parcial.
    * `amount`: El monto retirado.

* `event AuctionExtended(uint256 newEndTime)`:
    * Emitido cuando el plazo de la subasta se extiende debido a una oferta realizada cerca del final.
    * `newEndTime`: El nuevo `timestamp` de finalización de la subasta.

---

## Modificadores

Los modificadores son fragmentos de código reutilizables que se aplican a las funciones para validar condiciones previas.

* `onlyOwner()`:
    * Restringe la ejecución de una función solo al `owner` del contrato.
* `auctionActive()`:
    * Permite la ejecución de una función solo si la subasta está en curso y no ha terminado.
* `auctionEnded()`:
    * Permite la ejecución de una función solo si la subasta ha finalizado (ya sea por tiempo o por haber sido marcada como `ended`).

---

## Consideraciones de Seguridad

El contrato incorpora las siguientes medidas de seguridad:

* **Prevención de Reentrada:** Las funciones `returnDeposits()` y `partialWithdrawal()` siguen el patrón "Checks-Effects-Interactions" (Verificaciones-Efectos-Interacciones). Los balances de los usuarios se actualizan (`deposits[msg.sender] = 0;` o `deposits[msg.sender] = lastBidAmount;`) antes de que se realice cualquier transferencia de Ether (`call{value: ...}`). Esto previene ataques donde un contrato malicioso intenta llamar repetidamente la función de retiro antes de que el balance se actualice.
* **Validaciones `require()`:** Todas las funciones que manejan lógica crítica incluyen sentencias `require()` con mensajes descriptivos. Esto asegura que las precondiciones necesarias se cumplan antes de ejecutar operaciones que modifiquen el estado.
* **Manejo de Errores en Transferencias:** El uso de `(bool success, ) = payable(msg.sender).call{value: netRefund}("");` y la subsiguiente verificación `require(success, "...");` asegura que las transferencias de Ether sean exitosas y reviertan la transacción si no lo son.

---

## Licencia

Este proyecto está bajo la licencia `MIT License`. ( archivo `LICENSE` para más detalles.)

---
