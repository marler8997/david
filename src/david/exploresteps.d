#!/usr/bin/env rund
//!importPath ..

import core.stdc.stdlib : malloc, free;
import std.stdio;
import std.traits : isSigned;
import std.format;

import david.physics : absoluteValue, twoDimensionIterator;

void main()
{
    //dumpSteps(10,10);
    //dumpSteps(10,-10);
    //dumpSteps(-10, 10);
    //dumpSteps(-10, -10);

    //dumpSteps(5, 8);
    //dumpSteps(1,2);
    //dumpSteps(1,3);
    //dumpSteps(1,4);
    //dumpSteps(1,5);
    dumpSteps(1,6);


    /*
    dumpSteps(0, 0);
    dumpSteps(1, 0);
    dumpSteps(2, 0);
    dumpSteps(3, 0);

    dumpSteps(0, 1);
    dumpSteps(0, 2);
    dumpSteps(0, 3);
    */
    //dumpSteps(3, 3);

    //dumpSteps(29, 31);
    //dumpSteps(-29, 31);
    //dumpSteps(29, -31);
    //dumpSteps(-29, -31);

    //dumpSteps(60, 14);
    //dumpSteps(14, 60);

    //dumpSteps(10, 10);
    //dumpSteps(4, 8);
    //dumpSteps(4, 9);

    //test(3,3);
    //test(10,10);
    //test(5, 8);
    //test(29,33);
    //test(0,1);
    //test(0,2);
    //test(0,20);
    //test(0,0);

    //dumpSteps(-10, 4);
    //dumpSteps(9,-6);
    //dumpSteps(20,50);
    //dumpSteps(100,-57);
}

void test(int a, int b)
{
    writeln("---------------------------------------");
    auto iterator = twoDimensionIterator(a,b);
    int iteration = 0;
    for(; iterator.next(); iteration++)
    {
        if(iteration > 100)
        {
            assert(0);
        }
    }
}

struct Point
{
    int x;
    int y;
}
Point getStep(int vx, int vy, uint step)
{
    int maxV = (vx >= vy) ? vx : vy;
    return Point(
        (step * vx) / maxV,
        (step * vy) / maxV);
}


auto takeSignFrom(T)(T value, T signValue)
{
    return (signValue >= 0) ? value : -value;
}

auto normalizedUnitValue(T)(T value) if(isSigned!T)
{
    return (value > 0) ? 1 : ( (value < 0) ? -1 : 0);
}

void dumpSteps(int vx, int vy)
{
    static auto getCharsIndex(int rowCharLength, int vx, int vy, int dxAbsolute, int dyAbsolute)
    {
        if(vx > 0)
        {
            if(vy > 0)
            {
                return ((vy.absoluteValue - dyAbsolute) * rowCharLength) + dxAbsolute;
            }
            else
            {
                return (dyAbsolute * rowCharLength) + dxAbsolute;
            }
        }
        else
        {
            if(vy > 0)
            {
                return ((vy.absoluteValue - dyAbsolute) * rowCharLength) + (vx.absoluteValue - dxAbsolute);
            }
            else
            {
                return (dyAbsolute * rowCharLength) + (vx.absoluteValue - dxAbsolute);
            }
        }
    }


    writeln("----------------------------------------");
    writefln("dumpSteps %s x %s", vx, vy);
    writeln("----------------------------------------");

    auto vxAbsolute = vx.absoluteValue;
    auto vyAbsolute = vy.absoluteValue;

    auto rowCharLength = (vxAbsolute + 1) + 1; // Add 1 for the newline '\n'
    auto rowCount      = (vyAbsolute + 1);
    auto charsLength = rowCharLength * rowCount;

    char* chars = cast(char*)malloc(charsLength);
    scope(exit) free(chars);
    {
        auto rowIndex = 0;
        foreach(i; 0..rowCount)
        {
            auto nextRowIndex = rowIndex + rowCharLength - 1;
            chars[rowIndex..nextRowIndex] = '-';
            chars[nextRowIndex] = '\n';
            rowIndex = nextRowIndex + 1;
        }
    }

    chars[getCharsIndex(rowCharLength, vx, vy, 0, 0)] = '0';
    /*
    {
        auto point = getStep(vx, vy, 0);
        assert(point.x == 0 && point.y == 0, format(
            "getStep returned %s x %s at step %s which does not match %s x %s",
            point.x, point.y, 0, 0, 0));
    }
    */

    writeln("---------------------------------------");
    auto it = twoDimensionIterator(vx,vy);
    uint step = 0;
    for(; it.next(); step++)
    {
        auto signedValues = it.signedValues;
        writefln("[%s] diff %s x %s", step, signedValues[0], signedValues[1]);
        chars[getCharsIndex(rowCharLength, vx, vy, it.values[0], it.values[1])] = '+';
        {
            /*
            auto point = getStep(vx, vy, step);
            assert(point.x == dx && point.y == dy, format(
                "getStep returned %s x %s at step %s which does not match %s x %s",
                point.x, point.y, step, dx, dy));
            */
        }
    }

    write(chars[0..charsLength]);
}

