// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction {
    // --- Variables de Estado ---
    address public owner;
    uint256 public auctionStartTime;
    uint256 public auctionEndTime;
    uint256 public highestBid;
    address public highestBidder;
    bool public ended;

    // Mapeo para registrar el total depositado por cada participante
    mapping(address => uint256) public deposits;

    // Estructura para almacenar los detalles de cada oferta válida
    struct Bid {
        address bidder;
        uint256 amount;
    }

    // Mapeo para almacenar la última oferta registrada de cada participante
    mapping(address => Bid) public lastBids;

    // Lista de todas las direcciones que han ofertado, para `showBids`
    address[] public allBidders;
    // Mapeo auxiliar para verificar rápidamente si un ofertante ya está en `allBidders`
    mapping(address => bool) private hasBidder;

    // Constantes para las reglas de la subasta
    uint256 public constant EXTENSION_TIME = 10 minutes;
    uint256 public constant MIN_BID_INCREMENT_PERCENT = 5;
    uint256 public constant GAS_COMMISSION_PERCENT = 2; // Comisión del 2% para gas

    // --- Eventos ---
    event NewBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 winningBid);
    event DepositRefunded(address indexed beneficiary, uint256 amount);
    event PartialWithdrawal(address indexed bidder, uint256 amount);
    event AuctionExtended(uint256 newEndTime);

    // --- Constructor ---
    constructor(uint256 _durationInMinutes) {
        owner = msg.sender;
        auctionStartTime = block.timestamp;
        auctionEndTime = block.timestamp + (_durationInMinutes * 1 minutes);
        highestBid = 0;
        highestBidder = address(0);
        ended = false;
    }

    // --- Modificadores ---

    
    // La función solo puede llamarse por la dirección del propietario.
    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el propietario puede llamar a esta funcion.");
        _;
    }

    //Restringe el acceso a funciones solo si la subasta está activa.
// La función solo puede ser llamada si la subasta no ha finalizado.
    modifier auctionActive() {
        require(block.timestamp < auctionEndTime && !ended, "La subasta no esta activa.");
        _;
    }

    //Restringe el acceso a funciones solo si la subasta ha finalizado.
     
    modifier auctionEnded() {
        require(block.timestamp >= auctionEndTime || ended, "La subasta no ha finalizado.");
        _;
    }

    // --- Funciones ---

    //Permite a un participante realizar una oferta.
     // El monto de Ether se envía con la transacción (msg.value).
     //La oferta debe ser al menos un 5% mayor que la oferta actual más alta.
     //Extiende el plazo de la subasta si la oferta se realiza en los últimos 10 minutos.
     
    function bid() public payable auctionActive {
        uint256 requiredMinBid = highestBid + (highestBid * MIN_BID_INCREMENT_PERCENT / 100);
        if (highestBid == 0) {
            requiredMinBid = 1 wei; // La primera oferta debe ser al menos 1 wei
        }

        require(msg.value >= requiredMinBid, "La oferta debe ser al menos un 5% mayor que la oferta actual.");

        // Asçi añadir a   allBidders usando el mapeo `hasBidder`
        if (!hasBidder[msg.sender]) {
            hasBidder[msg.sender] = true;
            allBidders.push(msg.sender);
        }

        deposits[msg.sender] += msg.value;

        if (msg.value > highestBid) {
            highestBid = msg.value;
            highestBidder = msg.sender;
        }

        lastBids[msg.sender] = Bid(msg.sender, msg.value);

        emit NewBid(msg.sender, msg.value);

        if (auctionEndTime - block.timestamp <= EXTENSION_TIME && block.timestamp < auctionEndTime) {
            auctionEndTime += EXTENSION_TIME;
            emit AuctionExtended(auctionEndTime);
        }
    }

     //Marca la subasta como finalizada si el tiempo ha expirado. (Cualquiera puede llamar a esta función para finalizar la subasta.)
     
    function endAuction() public {
        require(block.timestamp >= auctionEndTime && !ended, "La subasta no puede finalizarse o ya ha finalizado.");
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
    }

    //  Muestra la dirección del ofertante ganador y el valor de la oferta ganadora.
     //Solo se puede llamar una vez que la subasta ha terminado.
     //@return winner La dirección del ofertante ganador.
     //@return winningBid El monto de la oferta ganadora.
     
    function showWinner() public view auctionEnded returns (address winner, uint256 winningBid) {
        return (highestBidder, highestBid);
    }

    // Muestra la lista de ofertantes y sus últimos montos ofrecidos.
     //Retorna arrays de direcciones y montos.
     //@return bidders Array de direcciones de los ofertantes.
     // @return amounts Array de los últimos montos ofrecidos por cada ofertante.
     
    function showBids() public view returns (address[] memory bidders, uint256[] memory amounts) {
        bidders = new address[](allBidders.length);
        amounts = new uint256[](allBidders.length);

        for (uint i = 0; i < allBidders.length; i++) {
            address currentBidder = allBidders[i];
            bidders[i] = currentBidder;
            amounts[i] = lastBids[currentBidder].amount;
        }
        return (bidders, amounts);
    }

    //Permite a los ofertantes que no ganaron reclamar su Ether depositado, descontando una comisión del 2%.
    //Solo se puede llamar una vez que la subasta ha terminado.
     
    function returnDeposits() public auctionEnded {
        // Asegurarse de que quien llama no sea el ganador
        require(msg.sender != highestBidder, "El ganador no puede reclamar un deposito de perdedor.");

        // Asegurarse de que el llamador tenga un depósito que reclamar
        uint256 amountToRefund = deposits[msg.sender];
        require(amountToRefund > 0, "No tienes depositos para reclamar.");

        // Calcular el monto a devolver después de la comisión del 2%
        uint256 commission = (amountToRefund * GAS_COMMISSION_PERCENT) / 100;
        uint256 netRefund = amountToRefund - commission;

        // Resetear el depósito del usuario a cero antes de la transferencia para evitar reentrancy
        deposits[msg.sender] = 0;

        // Transferir el Ether de vuelta al ofertante
        (bool success, ) = payable(msg.sender).call{value: netRefund}("");
        require(success, "Fallo la transferencia del reembolso.");

        emit DepositRefunded(msg.sender, netRefund);
    }

    //Permite a los participantes retirar el importe por encima de su última oferta válida durante el desarrollo de la subasta.
    //Solo se puede llamar mientras la subasta está activa.
     
    function partialWithdrawal() public auctionActive {
        // La cantidad que el usuario tiene depositada.
        uint256 currentDeposit = deposits[msg.sender];
        // La cantidad de su última oferta válida.
        uint256 lastBidAmount = lastBids[msg.sender].amount;

        // Si su depósito es igual o menor a su última oferta, no hay nada que retirar parcialmente.
        require(currentDeposit > lastBidAmount, "No hay monto excedente para retirar.");

        // Calcular el monto a retirar (depósito total - última oferta).
        uint256 amountToWithdraw = currentDeposit - lastBidAmount;

        // Restablecer el depósito del usuario ANTES de la transferencia para prevenir reentrancy.
        // El nuevo depósito será igual al monto de su última oferta.
        deposits[msg.sender] = lastBidAmount;

        // Realizar la transferencia del monto excedente.
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Fallo el retiro parcial.");

        emit PartialWithdrawal(msg.sender, amountToWithdraw);
    }
}