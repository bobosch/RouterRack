// Router model
model = "FB6590"; // [FB6590, FB7590]
// Rack width
rack_width = 19; // [10,19]
/* Construct custom rack mount here
*  - side: a wall between modules
*  These can be used only once:
*  - space: use the free space, only the front, no bottom behind
*  - spare: use the free space, front with bottom
*  - split: split the object with screw connectors
*  e. g. ["side", "FB6590","side","FB6590","side","spare"];
*/
mods = ["side", model, rack_width == 10 ? "side" : "split", "space"]; // [side, space, spare, split, FB6590, FB7590]
// Thickness of all walls
wall = 3.0; // 0.1
// Depth of rack mount
depth = 150;
// Diameter of the bottom holes
dia = 17;
// Connector (split) screw diameter
screw_size = 4; // [3:6]
// Connector (split) screw length
screw_length = 10;

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
[ 4  ,   3.8  ,   4    ,   7   ,  4.05,   3.2 ],
[ 5  ,   4.25 ,   5    ,   8   ,  4.63,   4   ],
[ 6  ,   5    ,   6    ,  10   ,  5.78,   5   ],
];

$fn=60;

HU = get_HU();
function get_HU(i = 0, res = 0) = i < len(mods) ? get_HU(i + 1, mod_HU(mods[i]) > res ? mod_HU(mods[i]) : res) : res;
function height() = (HU - 1) * R_MOUNT_HEIGHT + R_PANEL_HEIGHT;

sp_width = get_sp_width();
function get_sp_width(i = 0, res = 0) = i < len(mods) ? get_sp_width(i + 1, res + mod_width(mods[i])) : R_INNER_WIDTH - res;

split_width = get_split_width();
function get_split_width(i = 0, res = 0) = i < len(mods) && mods[i] != "split" ? get_split_width(i + 1, res + mod_width(mods[i])) : res + mod_width("mount") + mod_width(mods[i])/2;

if (split_width) {
    intersection() {
        rack_mount();
        translate([0, -wall, 0]) cube([split_width, depth+wall, height()]);
    }
    intersection() {
        rack_mount();
        translate([split_width, -wall, 0]) cube([R_OUTER_WIDTH-split_width, depth+wall, height()]);
    }
} else {
    rack_mount();
}

module rack_mount() {
    front("mount");
    draw_mods(0, R_MOUNT_WIDTH);
    translate([R_OUTER_WIDTH, 0]) mirror([1,0,0]) front("mount");
}

module draw_mods(i = 0, x = 0) {
    echo (mods[i],info(mods[i]));
    translate([x, 0, 0]) {
        front(mods[i]);
        bottom(mods[i]);
    }
    if (i < len(mods)-1) draw_mods(i + 1, x + mod_width(mods[i]));
}

module front(mod) {
    rotate([90, 0, 0]) linear_extrude(wall) difference() {
        square([mod_width(mod), height()]);
        translate([0, wall]) mods(mod, "front");
    }
}

module bottom(mod) {
    if (mod != "space") translate([mod_width(mod), 0, 0]) linear_extrude(wall) rotate([0, 0, 90]) honeycomb(depth, mod_width(mod), dia, wall, true);
//    translate([mod_width(mod), 0, 0]) linear_extrude(wall) rotate([0, 0, 90]) square([depth, mod_width(mod)]);
    mods(mod, "bottom");
}

function side_connector_width() = screw_length + M[screw_size][2];

module side_wall(connector = false) {
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
    p = [[-wall, 0], [-wall, height()], [0, height()], [depth, wall], [depth, 0]];

    difference() {
        polygon(points = p, paths= [[0, 1, 2, 3, 4]]);
        translate([8, 8+wall]) side_hole(type);
        translate([depth/2 + height()/2 - 4, 8+wall]) side_hole(type);
        if (HU > 1) translate([8, height() - 14]) side_hole(type);
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

module mods(mod, part) {
    if (mod == "mount") mount(part);
    else if (mod == "side") side(part);
    else if (mod == "space") space(part);
    else if (mod == "spare") spare(part);
    else if (mod == "split") split(part);
    else if (mod == "FB6590") fb6590(part);
    else if (mod == "FB7590") fb7590(part);
}

function info(mod) = 
    mod == "mount" ? mount_info() :
    mod == "side" ? side_info() :
    mod == "space" ? space_info() :
    mod == "spare" ? spare_info() :
    mod == "split" ? split_info() :
    mod == "FB6590" ? fb6590_info() :
    mod == "FB7590" ? fb7590_info() :
    [];
function mod_HU(mod) = info(mod)[0];
function mod_width(mod) = info(mod)[1];

// Mounting hole
function mount_info() = [HU, R_MOUNT_WIDTH];
module mount(part) {
    module hole() {
        hull() {
            translate([-1.5,0]) circle(d=R_HOLE_DIA);
            translate([+1.5,0]) circle(d=R_HOLE_DIA);
        }
    }

    translate([0, -wall]) {
        // Rounded edges
        difference() {
            square([R_MOUNT_WIDTH+5, height()]);
            offset(r = 3) offset(r = -3) square([R_MOUNT_WIDTH+5, height()]);
        }

        for (i = [1 : HU]) {
            offset = (i - 1) * R_MOUNT_HEIGHT;
            translate([R_HOLE_OFFSET, offset + R_HOLE_BOTTOM]) hole();
            translate([R_HOLE_OFFSET, offset + R_HOLE_MID]) hole();
            translate([R_HOLE_OFFSET, offset + R_HOLE_TOP]) hole();
        }
    }
}

// Side wall
function side_info() = [0, wall];
module side(part) {
    if (part == "bottom") side_wall(false);
}

// Space with no bottom
function space_info() = [0, sp_width ? sp_width : 0];
module space(part) {
}

// Spare with empty bottom
function spare_info() = [0, sp_width ? sp_width : 0];
module spare(part) {
}

// Split module with screw connector
function split_info() = [0, side_connector_width()];
module split(part) {
    if (part == "bottom") side_wall(true);
}

// FritzBox 6590
function fb6590_info() = [2, 209];
module fb6590(part) {
    if (part == "front") {
        translate([10, 11.7]) square([199, 60.6]);
    } else if (part == "bottom") {
        translate([145, 0, 0]) cube([7, depth, 11.7 + wall]);
    }
}

// FritzBox 7590
function fb7590_info() = [1, 250];
module fb7590(part) {
    if (part == "front") {
        translate([6.5,  0]) square([237, 33]);
        translate([1.5, 25]) square([247,  8]);
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
