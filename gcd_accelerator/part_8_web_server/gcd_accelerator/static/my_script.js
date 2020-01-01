var margin = {top: 20, right: 20, bottom: 20, left: 60},
    width = 200 - margin.left - margin.right,
    height = 200 - margin.top - margin.bottom;

var zeros = [
    { name: 'CPU', value: 0.0 },
    { name: 'FPGA', value: 0.0 },
];

var xScale = d3.scale.ordinal()
    .rangeRoundBands([0, width], .3)
    .domain(zeros.map(function(d) { return d.name; }));

var yScale = d3.scale.linear()
    .range([height, 0])
    .domain([0, 1000]);

var xAxis = d3.svg.axis()
    .scale(xScale)
    .orient("bottom");

var yAxis = d3.svg.axis()
    .scale(yScale)
    .orient("left")
    .ticks(5);

var svg = d3.select("#svg_chart")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
    .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

var tip = d3.tip()
.attr('class', 'd3-tip')
    .offset([-10, 0])
    .html(function(d) {
        return "<strong>" + d.value + " ns</strong>";
    })

svg.call(tip);

svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
    .call(xAxis)
        .selectAll("text")
        .style("text-anchor", "middle")

svg.append("g")
        .attr("class", "y axis")
    .call(yAxis)
    .append("text")
        .attr("transform", "rotate(-90)")
        .attr("x", 0-(height/2))
        .attr("y", 0-45)
        .style("text-anchor", "middle")
        .text("Execution time [ns]");

svg.selectAll("bar")
        .data(zeros)
        .enter()
    .append("rect")
        .attr("class", "bar")
        .attr("x", function(d) { return xScale(d.name); })
        .attr("width", xScale.rangeBand())
        .attr("y", function(d) { return yScale(d.value); })
        .attr("height", function(d) { return height - yScale(d.value); })
        .on('mouseover', tip.show)
        .on('mouseout', tip.hide);

function updateChart(data) {
    d3.selectAll("rect")
        .data(data)
        .transition()
        .duration(500)
        .attr("y", function(d) { return yScale(d.value); })
        .attr("height", function(d) { return height - yScale(d.value); });
}

// On click event for button calculate
$('#btn_calculate').click(function() {
    // *** Construct HTTP request data ***
    var request = {
        // Get input A and B from HTML input
        a: $('#inp_a').val(),
        b: $('#inp_b').val(),
    };
    console.log(request);

    // Send HTTP request to the web server, and process HTTP response
    $.post(window.location.origin, JSON.stringify(request), function(response) {
        console.log(response);

        // *** Process HTTP response ***
        // Display GCD result and speed up 
        $('#txt_c').text(response.c);
        $('#txt_speed_up').text(response.speed_up);
        // Update chart
        var data = [
            { name: 'CPU', value: response.sw_time },
            { name: 'FPGA', value: response.hw_time },
        ];
        updateChart(data);
    });
});

// On click event for button reset
$('#btn_reset').click(function() {
    // Clear all inputs and outputs
    $('#inp_a').val('');
    $('#inp_b').val('');
    $('#txt_c').text('0');
    $('#txt_speed_up').text('0');
    updateChart(zeros);
});