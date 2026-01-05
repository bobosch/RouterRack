model = "FB6590"; // [FB6590,FB7590]
rack_width = 19; // [10,19]
split = true;
wall = 3;
screw_size = 4; // [3:6]
screw_length = 10;
dia = 17;

/* [Hidden] */

// convert inch to mm (to use standardized 19" dimensions below)
function mm(inch) = inch * 25.4;    

// 19" rack dimensions
R_OUTER_WIDTH = mm(rack_width); // outer width of rack
R_MOUNT_WIDTH = mm(0.625); // width of mounting area
R_MOUNT_HEIGHT = mm(1.75); // height of 1U rack unit
R_PANEL_HEIGHT = mm(1.71875); // panel height for a 1U unit
R_INNER_WIDTH = R_OUTER_WIDTH - (2*R_MOUNT_WIDTH); // inner width 
R_HOLE_OFFSET = mm(11/16) / 2.0; // horizontal hole offset from the edge

// vertical distances of the 3 mounting holes from the bottom
R_HOLE_BOTTOM = mm(0.25);
R_HOLE_MID = mm(0.625) + R_HOLE_BOTTOM;
R_HOLE_TOP = mm(0.625) + R_HOLE_MID;

// Diameter (mm) of the front panel's holes
R_HOLE_DIA = 6.4;
R_SQUARE_HOLE_WIDTH = mm(0.375); // width of square hole for cage nuts

M = [
[0],
// 0 |   1    |   2    |   3   |  4   |   5
// M | head r | head h | nut w |nut r | nut h
[ 2  ,   1.9  ,   2    ,   4   ,  0   ,   1.6 ],
[ 2.5,   2.25 ,   2.5  ,   5   ,  0   ,   2   ],
[ 3  ,   2.75 ,   3    ,   5.5 ,  3.18,   2.4 ],
[ 4  ,   3.5  ,   4    ,   7   ,  4.05,   3.2 ],
[ 5  ,   4.25 ,   5    ,   8   ,  4.63,   4   ],
[ 6  ,   5    ,   6    ,  10   ,  5.78,   5   ],
];

$fn=60;

HU = router_HU();
depth = router_depth();

left_width = R_MOUNT_WIDTH+wall+router_width()+side_connector_width()/2;
height = (HU - 1) * R_MOUNT_HEIGHT + R_PANEL_HEIGHT;

if (split) {
    intersection() {
        rack_mount();
        translate([0, -wall, 0]) cube([left_width, depth+wall, height]);
    }
    intersection() {
        rack_mount();
        translate([left_width, -wall, 0]) cube([R_OUTER_WIDTH-left_width, depth+wall, height]);
    }
} else {
    rack_mount();
}

module rack_mount() {
    front(HU);
    translate([R_MOUNT_WIDTH, 0, 0]) {
        side();
        translate([wall, 0, 0]) bottom(router_width());
    }
    translate([R_MOUNT_WIDTH+wall+router_width(), 0, 0]) {
        side(split);
        translate([side_connector_width(), 0, 0]) bottom(R_INNER_WIDTH-router_width()-side_connector_width()-2*wall);
    }
    translate([R_OUTER_WIDTH-R_MOUNT_WIDTH-wall, 0, 0]) side();
}

module front(HU) {
    rotate([90, 0, 0]) linear_extrude(wall) offset(r = 1) offset(r = -1) difference() {
        square([R_OUTER_WIDTH, height]);
        mount(HU);
        translate([R_OUTER_WIDTH, 0]) mirror([1,0,0]) mount(HU);
        translate([R_MOUNT_WIDTH+wall, wall]) {
            if (model == "FB6590") fb6590_front();
            else if (model == "FB7590") fb7590_front();
        }
    }
}

module bottom(width) {
    translate([width, 0, 0]) linear_extrude(wall) rotate([0, 0, 90]) honeycomb(depth, width, dia, wall, true);
//    translate([width, 0, 0]) linear_extrude(wall) rotate([0, 0, 90]) square([depth, width]);
    if (width == router_width() && model == "FB6590") fb6590_bottom();
}

function side_connector_width() = split ? screw_length + M[screw_size][2] : wall;

module side(connector = false) {
    length_head = M[screw_size][2];
    length_nut = M[screw_size][5];
    length_hole = screw_length-length_nut;

    rotate([90, 0, 90]) {
        if (connector) {
            linear_extrude(length_head) side_shape("head");
            translate([0, 0, length_head]) linear_extrude(length_hole) side_shape("hole");
            translate([0, 0, length_head+length_hole]) linear_extrude(length_nut) side_shape("nut");
        } else {
            linear_extrude(wall) side_shape("");
        }
    }
}

module side_shape(type) {
    p = [[0, 0], [0, height], [depth, wall], [depth, 0]];

    difference() {
        polygon(points = p, paths= [[0, 1, 2, 3]]);
        translate([8, 8+wall]) side_hole(type);
        translate([depth/2 + height/2 - 4, 8+wall]) side_hole(type);
        if (HU > 1) translate([8, height - 14]) side_hole(type);
    }
}

module side_hole(type) {
    if(type == "hole") {
        circle(screw_size/2 + 0.1);
    } else if (type =="head") {
        circle(M[screw_size][1] + 0.1);
    } else if (type =="nut") {
        circle(M[screw_size][4] + 0.1, $fn=6); // 7 mm
    }
}

function dimensions() = 
    model == "FB6590" ? fb6590_dimensions() :
    model == "FB7590" ? fb7590_dimensions() :
    [];
function router_HU() = dimensions()[0];
function router_width() = dimensions()[1];
function router_depth() = dimensions()[2];

function fb6590_dimensions() = [2, 209, 150]; // 170 ?
module fb6590_front() {
    translate([10, 11.66]) square([199, 60.7]);
}
module fb6590_bottom() {
    height = 12+wall;
    bottom = 9;
//    p = [[0, 0], [bottom, 0], [bottom, height], [0,wall]];
    translate([145, 0, 0]) {
        cube([7, router_depth(), 12+wall]);
//        translate([0, -bottom, 0]) rotate([90, 0, 90]) linear_extrude(7) polygon(points = p, paths= [[0, 1, 2, 3]]);
    }
    
}

function fb7590_dimensions() = [1, 250, 150];
module fb7590_front() {
    translate([6.5,  0]) square([237, 33]);
    translate([1.5, 25]) square([247,  8]);
}

module mount(HU) {
    module hole() {
        hull() {
            translate([-1.5,0]) circle(d=R_HOLE_DIA);
            translate([+1.5,0]) circle(d=R_HOLE_DIA);
        }
    }

    for (i = [1 : HU]) {
        offset = (i - 1) * R_MOUNT_HEIGHT;
        translate([R_HOLE_OFFSET, offset + R_HOLE_BOTTOM]) hole();
        translate([R_HOLE_OFFSET, offset + R_HOLE_MID]) hole();
        translate([R_HOLE_OFFSET, offset + R_HOLE_TOP]) hole();
    }
}

// parametric honeycomb
module honeycomb(x, y, dia, wall, whole_only=false)  {
    // Diagram
    //          ______     ___
    //         /     /\     |
    //        / dia /  \    | smallDia
    //       /     /    \  _|_
    //       \          /   ____
    //        \        /   /
    //     ___ \______/   /
    // wall |            /
    //     _|_  ______   \
    //         /      \   \
    //        /        \   \
    //                 |---|
    //                   projWall
    //

    // a single filled hexagon
    module hexagon(xoff, yoff)  {
        radius = dia / 2;
        if (
                !whole_only || (
                    (xoff - radius >= -x/2 && xoff + radius <= x/2)
                    && (yoff - radius >= -y/2 && yoff + radius <= y/2)
                )
        ) {
            translate([xoff, yoff])
            circle(d=dia, $fn=6);
        }
    }

    smallDia = dia * cos(30);
    projWall = wall * cos(30);

    yStep = smallDia + wall;
    xStep = dia*3/2 + projWall*2;

    yStepsCount = ceil((y/2) / yStep);
    xStepsCount = ceil((x/2) / xStep);

    difference() {
        square([x, y]);
        translate([x/2, y/2])
        for (
                yOffset = [-yStep * yStepsCount : yStep : yStep * yStepsCount],
                xOffset = [-xStep * xStepsCount : xStep : xStep * xStepsCount]
        ) {
            hexagon(xOffset, yOffset);
            hexagon(xOffset + dia*3/4 + projWall, yOffset + (smallDia+wall)/2);
        }
    }
}
