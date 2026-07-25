// Data sementara
// nanti diganti API Database


const orderData = {


total:0,

process:0,

delivery:0,

done:0


};





document.getElementById("totalOrder").innerHTML =
orderData.total;



document.getElementById("orderProcess").innerHTML =
orderData.process;



document.getElementById("orderDelivery").innerHTML =
orderData.delivery;



document.getElementById("orderDone").innerHTML =
orderData.done;




document.getElementById("orderCount").innerHTML =
orderData.total + " Data";