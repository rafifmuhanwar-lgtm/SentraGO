
const dashboardData = {


    totalUser: 0,


    totalDriver: 0,


    totalOrder: 0,


    totalIncome: 0,


    orderChart: [

        0,
        0,
        0,
        0,
        0,
        0,
        0

    ]


};





// Update Card Dashboard


document.getElementById("totalUser").innerHTML =
dashboardData.totalUser;



document.getElementById("totalDriver").innerHTML =
dashboardData.totalDriver;



document.getElementById("totalOrder").innerHTML =
dashboardData.totalOrder;



document.getElementById("totalIncome").innerHTML =
"Rp" + dashboardData.totalIncome;








// Chart Dashboard


const ctx = document.getElementById("myChart");



new Chart(ctx, {


    type:"line",


    data:{


        labels:[

            "Sen",
            "Sel",
            "Rab",
            "Kam",
            "Jum",
            "Sab",
            "Min"

        ],


        datasets:[

            {

                label:"Jumlah Pesanan",


                data:dashboardData.orderChart,


                fill:true,


                tension:0.4,


                pointRadius:5,


                pointHoverRadius:7,


                borderWidth:3


            }

        ]


    },


    options:{


        responsive:true,


        maintainAspectRatio:false,


        plugins:{


            legend:{


                display:true,


                position:"top"


            },


            tooltip:{


                enabled:true


            }


        },


        scales:{


            y:{


                beginAtZero:true,


                ticks:{


                    stepSize:5


                }


            },


            x:{


                grid:{


                    display:false


                }


            }


        }


    }



});