module david.physics;

import std.format : format, formattedWrite;
import std.typecons : Flag, Yes, No;
import std.traits : Unqual, isIntegral, isSigned, isUnsigned;
import std.algorithm : max;

import david.types;

auto absoluteValue(T)(T value) if(isSigned!T)
{
    return (value >= 0) ? value : -value;
}
pragma(inline)
auto absoluteValue(T)(T value) if(isUnsigned!T)
{
    return value;
}
auto absoluteValue(Unit unit)
{
    return (unit.value >= 0) ? unit : Unit(-unit.value);
}
auto absoluteValue(UnsignedUnit unit)
{
    return unit;
}

/*
T normalizeToOne(T)(T value)
{
    if(value > 0) return T(1);
    if(value < 0) return T(-1);
    return T(0);
}
unittest
{
    assert(1 == normalizeToOne(100));
    assert(0 == normalizeToOne(0));
    assert(-1 == normalizeToOne(-100));

    assert(1 == normalizeToOne(cast(long)100));
    assert(0 == normalizeToOne(cast(long)0));
    assert(-1 == normalizeToOne(cast(long)-100));
}
*/

private template MassTemplate(Flag!"supportInfinite" supportInfinite)
{
    private struct Mass
    {
        uint value;

        static if(supportInfinite)
        {
            static @property Mass infinite() { return Mass(value.max); }
            @property bool isInfinite() { return value == value.max; }
        }

        bool opEquals(Mass rhs) const { return value == rhs.value; }
        int opCmp(Mass rhs) const
        {
            return value - rhs.value;
        }
        void opOpAssign(string op)(Mass other)
        {
            mixin("value "~op~"= other.value;");
        }
        inout(Mass) opBinary(string op)(inout(Mass) rhs) inout
        {
            mixin("return Mass(value "~op~" rhs.value);");
        }
        void contentToString(scope void delegate(const(char)[]) sink) const
        {
            formattedWrite(sink, "%s", value);
        }
        void toString(scope void delegate(const(char)[]) sink) const
        {
            sink("Mass(");
            contentToString(sink);
            sink(")");
        }
    }
}
alias MassWithInfinite = MassTemplate!(Yes.supportInfinite).Mass;
alias MassNoInfinite   = MassTemplate!(No.supportInfinite).Mass;


template isSignedGameType(T)
{
    enum isSignedGameType = is( Unqual!T == Unit) || isSigned!T;
}


struct UnsignedUnit
{
    Unit unitValue;
    alias unitValue this;
    this(Unit unitValue)
        in { assert(unitValue.value >= 0); } body
    {
        this.unitValue = unitValue;
    }
}
auto unsignedUnit(T)(T value) if(isSigned!T)
    in { assert(value >= 0); } body
{
    return UnsignedUnit(Unit(value));
}
pragma(inline)
auto unsignedUnit(T)(T value) if(isUnsigned!T)
{
    return UnsignedUnit(Unit(value));
}


auto absoluteUnsignedUnit(T)(T value) if(isSigned!T)
{
    return unsignedUnit(value.absoluteValue);
    //return (value >= 0) ? UnsignedUnit(Unit(value)) : UnsignedUnit(Unit(-value));
}
pragma(inline)
auto absoluteUnsignedUnit(T)(T value) if(isUnsigned!T)
{
    return UnsignedUnit(Unit(value));
}
@property auto absoluteUnsignedUnit(Unit unit)
{
    return UnsignedUnit(unit.absoluteValue);
}
pragma(inline)
@property auto absoluteUnsignedUnit(UnsignedUnit unit)
{
    return unit;
}

unittest
{
    foreach(i; [int.min, -100, -1, 0, 1, 100, int.max])
    {
        assert(Unit(i) == Unit(i));
        assert(Unit(i) <= Unit(i));
        assert(Unit(i) >= Unit(i));

        assert(!(Unit(i) > Unit(i)));
        assert(!(Unit(i) < Unit(i)));
    }
}


bool collisionCheck(Flag!"supportExistingOverlap" supportExistingOverlap)(
    const ref UnitRectangle this_, UnitVector velocity, UnitRectangle checkRect, CollisionCheckResult* result)
{
    static if(supportExistingOverlap)
    {
        if(this_.overlap(checkRect))
        {
            *result = CollisionCheckResult(collisionTime(0,0));
            return true;
        }
    }
    else
    {
        assert(!this_.overlap(checkRect), "collisionCheck called with rectangles that already overlap");
    }

    // Small optimization
    {
        // Create a rectangle that includes all the potential space for collsion. Note
        // that this is a superset of all the space this object will occupy during this
        // movement, so if there is a collision with this space it does not necessarily
        // mean there is a collision with the object.
        auto fullMovementContainingRectangle = UnitRectangle(
            containingLine(this_.xLine, this_.xLine + velocity.x),
            containingLine(this_.yLine, this_.yLine + velocity.y));

        if(!fullMovementContainingRectangle.overlap(checkRect))
        {
            return false; // no collision
        }
    }

    // Check each movment step to see if there actually was a collision
    auto iterator = twoDimensionIterator(velocity.x.value, velocity.y.value);
    auto lastNoCollisionOffset = typeof(iterator.signedValues).init;
    while(true)
    {
        auto iterationResult = iterator.next();
        if(TwoIteratorResult.done == iterationResult)
        {
            break;
        }
        // Create a rectangle that represents the area moved by the front-facing side
        auto nextRectangle = UnitRectangle(
            this_.xLine + iterator.signedValues[0],
            this_.yLine + iterator.signedValues[1]);
        if(nextRectangle.overlap(checkRect))
        {
            CollisionDirection direction;
            CollisionTime time;
            if(TwoIteratorResult.first == iterationResult)
            {
                direction = CollisionDirection.x;
                time = collisionTime(iterator.values[0], velocity.x);
            }
            else if(TwoIteratorResult.second == iterationResult)
            {
                direction = CollisionDirection.y;
                time = collisionTime(iterator.values[1], velocity.y);
            }
            else
            {
                direction = CollisionDirection.xAndY;
                time = collisionTime(iterator.values[0], velocity.x);
            }


            *result = CollisionCheckResult(time,
                unitVector(lastNoCollisionOffset[0], lastNoCollisionOffset[1]),
                direction);
            return true;
        }
        lastNoCollisionOffset = iterator.signedValues;
    }
    return false; // no collision
}

// Works as flags and a value
enum CollisionDirection : ubyte
{
    x     = 0x01,
    y     = 0x10,
    xAndY = 0x11,
}

struct CollisionCheckResult
{
    // The time in which the collision would occur
    CollisionTime time;
    // The required diff in velocity to avoid the collision
    UnitVector noCollisionMove;
    // The direction(s) that caused the collision
    CollisionDirection direction;

    void contentToString(scope void delegate(const(char)[]) sink) const
    {
        if(time.distance.isZero)
        {
            sink("0");
        }
        else
        {
            time.contentToString(sink);
            sink(", noCollisionMove ");
            noCollisionMove.contentToString(sink);
            formattedWrite(sink, ", direction %s", direction);

        }
    }
    void toString(scope void delegate(const(char)[]) sink) const
    {
        sink("CollisionCheckResult(");
        contentToString(sink);
        sink(")");
    }
}

struct CollisionTime
{
    // The distance until the collision
    UnsignedUnit distance;

    // The velocity that the collision is being approached at
    UnsignedUnit velocity;

    bool opEquals(CollisionTime rhs) const
    {
        return opCmp(rhs) == 0;
    }
    int opCmp(CollisionTime rhs) const
    {
        if(velocity.isZero)
        {
            return (rhs.velocity.isZero) ? 0 : -1;
        }
        else
        {
            // TODO: handle overflow correctly
            return ((distance * rhs.velocity) - (rhs.distance * velocity)).value;
        }
    }
    /*
    void opOpAssign(string op)(CollisionTime unit)
    {
        mixin("distance "~op~"= distance.value;");
        mixin("velocity "~op~"= velocity.value;");
    }
    inout(CollisionTime) opBinary(string op)(inout(CollisionTime) rhs) inout
    {
        mixin("return CollisionTime(value "~op~" rhs.value);");
    }
    */
    void contentToString(scope void delegate(const(char)[]) sink) const
    {
        if(distance == Unit(0))
        {
            sink("0");
        }
        else
        {
            formattedWrite(sink, "%s/%s, %s", distance.value, velocity.value,
                (cast(float)distance.value) / (cast(float)velocity.value));
        }
    }
    void toString(scope void delegate(const(char)[]) sink) const
    {
        sink("CollisionTime(");
        contentToString(sink);
        sink(")");
    }
}
auto collisionTime(T,U)(T distance, U velocity)
{
    return CollisionTime(distance.absoluteUnsignedUnit, velocity.absoluteUnsignedUnit);
}

unittest
{
    assert(collisionTime(Unit(50), Unit(1)) < collisionTime(Unit(100), Unit(1)));
    assert(!(collisionTime(Unit(50), Unit(1)) > collisionTime(Unit(100), Unit(1))));

    foreach(i; [Unit.min, -100, -1, 0, 1, 100, Unit.max])
    {
        assert(collisionTime(i,1) == collisionTime(i, 1));
        assert(collisionTime(i,1) <= collisionTime(i, 1));
        assert(collisionTime(i,1) >= collisionTime(i, 1));

        assert(!(collisionTime(i, 1) > collisionTime(i, 1)));
        assert(!(collisionTime(i, 1) < collisionTime(i, 1)));
    }

    assert(collisionTime(4, 2) == collisionTime(2, 1));
    assert(collisionTime(5, 2) >  collisionTime(6, 3));
}

enum TwoIteratorResult
{
    done = 0, first, second, both
}

auto twoDimensionIterator(T)(T a, T b)
{
    return TwoDimensionIterator!T([a,b]);
}
struct TwoDimensionIterator(T)
{
    T[2] values;
    private T[2] weights;
    private T[2] nextWeightedValues;
    private T finalWeightedValue;
    static if(isSigned!T)
    {
        private bool[2] negative;
    }

    this(T[2] counts)
    {
        this.weights[0] = counts[0].absoluteValue + 1;
        this.weights[1] = counts[1].absoluteValue + 1;
        this.nextWeightedValues[0] = this.weights[1];
        this.nextWeightedValues[1] = this.weights[0];
        this.finalWeightedValue = this.nextWeightedValues[0] * this.nextWeightedValues[1];
        static if(isSigned!T)
        {
            negative[0] = counts[0] < 0;
            negative[1] = counts[1] < 0;
        }
    }
    static if(isSigned!T)
    {
        @property T[2] signedValues()
        {
            T[2] result;
            result[0] = negative[0] ? -values[0] : values[0];
            result[1] = negative[1] ? -values[1] : values[1];
            return result;
        }
    }

    @property TwoIteratorResult next()
    {
        if(nextWeightedValues[0] < nextWeightedValues[1])
        {
            //writefln("ADD 0");
            values[0]++;
            nextWeightedValues[0] += weights[1].absoluteValue;
            return TwoIteratorResult.first;
        }

        if(nextWeightedValues[0] > nextWeightedValues[1])
        {
            //writefln("ADD 1");
            values[1]++;
            nextWeightedValues[1] += weights[0].absoluteValue;
            return TwoIteratorResult.second;
        }

        if(nextWeightedValues[0] == finalWeightedValue)
        {
            return TwoIteratorResult.done;
        }

        //writefln("ADD 0,1 (next %s x %s, final %s)",
        //    nextWeightedValues[0], nextWeightedValues[1], finalWeightedValue);
        values[0]++;
        values[1]++;
        nextWeightedValues[0] += weights[1].absoluteValue;
        nextWeightedValues[1] += weights[0].absoluteValue;
        return TwoIteratorResult.both;
    }
}

unittest
{
    {
        auto iterator = twoDimensionIterator(0,0);
        assert(!iterator.next);
    }
    template tuple(T...)
    {
        alias tuple = T;
    }

    enum Iterations = 20;
    foreach(T; tuple!(int,uint))
    {
        foreach(T count; 0..Iterations)
        {
            {
                auto iterator = twoDimensionIterator!T(count, 0);
                foreach(T i; 1..count + 1)
                {
                    assert(iterator.next());
                    assert(iterator.values[0] == i);
                    assert(iterator.values[1] == 0);
                }
                assert(!iterator.next());
            }
            {
                auto iterator = twoDimensionIterator!T(0, count);
                foreach(T i; 1..count + 1)
                {
                    assert(iterator.next());
                    assert(iterator.values[0] == 0);
                    assert(iterator.values[1] == i);
                }
                assert(!iterator.next());
            }
            {
                auto iterator = twoDimensionIterator!T(count, count);
                foreach(T i; 1..count + 1)
                {
                    assert(iterator.next());
                    assert(iterator.values[0] == i);
                    assert(iterator.values[1] == i);
                }
                assert(!iterator.next());
            }
        }
    }

    foreach(int count; 0..Iterations)
    {
        {
            auto iterator = twoDimensionIterator!int(count, -count);
            foreach(int i; 1..count + 1)
            {
                assert(iterator.next());
                assert(iterator.signedValues[0] ==  i);
                assert(iterator.signedValues[1] == -i);
            }
            assert(!iterator.next());
        }
        {
            auto iterator = twoDimensionIterator!int(-count, count);
            foreach(int i; 1..count + 1)
            {
                assert(iterator.next());
                assert(iterator.signedValues[0] == -i);
                assert(iterator.signedValues[1] ==  i);
            }
            assert(!iterator.next());
        }
        {
            auto iterator = twoDimensionIterator!int(-count, -count);
            foreach(int i; 1..count + 1)
            {
                assert(iterator.next());
                assert(iterator.signedValues[0] == -i);
                assert(iterator.signedValues[1] == -i);
            }
            assert(!iterator.next());
        }
    }

    // TODO: add some more unittest that use "uneven" dimensions
    static struct TwoInts
    {
        int[2] values;
        this(int[2] values...)
        {
            this.values = values;
        }
    }
    static struct TestCase
    {
        int a;
        int b;
        TwoInts[] values;
    }
    auto testCases = [
        // Note: only use positive values here because all 4 variations on the negative versions will also be tested
        TestCase(1,2, [
            TwoInts(0,1),
            TwoInts(1,1),
            TwoInts(1,2),
        ]),
        TestCase(1,3, [
            TwoInts(0,1),
            TwoInts(1,2),
            TwoInts(1,3),
        ]),
        TestCase(1,4, [
            TwoInts(0,1),
            TwoInts(0,2),
            TwoInts(1,2),
            TwoInts(1,3),
            TwoInts(1,4),
        ]),
        TestCase(1,5, [
            TwoInts(0,1),
            TwoInts(0,2),
            TwoInts(1,3),
            TwoInts(1,4),
            TwoInts(1,5),
        ]),
        TestCase(1,6, [
            TwoInts(0,1),
            TwoInts(0,2),
            TwoInts(0,3),
            TwoInts(1,3),
            TwoInts(1,4),
            TwoInts(1,5),
            TwoInts(1,6),
        ]),
        TestCase(5,8, [
            TwoInts(0,1),
            TwoInts(1,1),
            TwoInts(1,2),
            TwoInts(2,3),
            TwoInts(2,4),
            TwoInts(3,4),
            TwoInts(3,5),
            TwoInts(4,6),
            TwoInts(4,7),
            TwoInts(5,7),
            TwoInts(5,8),
        ]),
    ];
    foreach(testCase; testCases)
    {
        {
            auto iterator = twoDimensionIterator(testCase.a, testCase.b);
            foreach(i, value; testCase.values)
            {
                assert(iterator.next());
                assert(testCase.values[i].values[0] == iterator.signedValues[0]);
                assert(testCase.values[i].values[1] == iterator.signedValues[1]);
            }
            assert(!iterator.next());
        }
        {
            auto iterator = twoDimensionIterator(testCase.b, testCase.a);
            foreach(i, value; testCase.values)
            {
                assert(iterator.next());
                assert(testCase.values[i].values[0] == iterator.signedValues[1]);
                assert(testCase.values[i].values[1] == iterator.signedValues[0]);
            }
            assert(!iterator.next());
        }

        {
            auto iterator = twoDimensionIterator(testCase.a, -testCase.b);
            foreach(i, value; testCase.values)
            {
                assert(iterator.next());
                assert(testCase.values[i].values[0] == iterator.signedValues[0]);
                assert(-testCase.values[i].values[1] == iterator.signedValues[1]);
            }
            assert(!iterator.next());
        }
        {
            auto iterator = twoDimensionIterator(-testCase.b, testCase.a,);
            foreach(i, value; testCase.values)
            {
                assert(iterator.next());
                assert(testCase.values[i].values[0] == iterator.signedValues[1]);
                assert(-testCase.values[i].values[1] == iterator.signedValues[0]);
            }
            assert(!iterator.next());
        }

        {
            auto iterator = twoDimensionIterator(-testCase.a, testCase.b);
            foreach(i, value; testCase.values)
            {
                assert(iterator.next());
                assert(-testCase.values[i].values[0] == iterator.signedValues[0]);
                assert(testCase.values[i].values[1] == iterator.signedValues[1]);
            }
            assert(!iterator.next());
        }
        {
            auto iterator = twoDimensionIterator(testCase.b, -testCase.a);
            foreach(i, value; testCase.values)
            {
                assert(iterator.next());
                assert(-testCase.values[i].values[0] == iterator.signedValues[1]);
                assert(testCase.values[i].values[1] == iterator.signedValues[0]);
            }
            assert(!iterator.next());
        }

        {
            auto iterator = twoDimensionIterator(-testCase.a, -testCase.b);
            foreach(i, value; testCase.values)
            {
                assert(iterator.next());
                assert(-testCase.values[i].values[0] == iterator.signedValues[0]);
                assert(-testCase.values[i].values[1] == iterator.signedValues[1]);
            }
            assert(!iterator.next());
        }
        {
            auto iterator = twoDimensionIterator(-testCase.b, -testCase.a);
            foreach(i, value; testCase.values)
            {
                assert(iterator.next());
                assert(-testCase.values[i].values[0] == iterator.signedValues[1]);
                assert(-testCase.values[i].values[1] == iterator.signedValues[0]);
            }
            assert(!iterator.next());
        }
    }
}

void handleCollisions(Flag!"supportExistingOverlap" supportExistingOverlap, T, U)
    (T movingEntityRange, U collidableRange)
{
    // Note: this loop is innefficient
    // Keep looping through all the moving entities and change their velocities
    // to avoid collisions with static entities.
    for (uint collisionRound = 0;; collisionRound++)
    {
        uint movingEntityCollisionCount = 0; // 1 for every moving entity that has a collision

        foreach (ref movingEntity; movingEntityRange)
        {
            if(movingEntity.currentStepVelocityLeft.isZero)
            {
                continue;
            }

            // For now I'm only checking collisions with static entities
            foreach (ref collidable; collidableRange)
            {
                CollisionCheckResult checkResult;
                if(collisionCheck!(supportExistingOverlap)(movingEntity.rectangle,
                        movingEntity.currentStepVelocityLeft, collidable.rectangle, &checkResult))
                {
                    bool setCollision;
                    if(!movingEntity.collision.isSet)
                    {
                        movingEntityCollisionCount++;
                        setCollision = true;
                    }
                    else
                    {
                        setCollision = checkResult.time < movingEntity.collision.check.time;
                    }

                    if(setCollision)
                    {
                        movingEntity.collision = Collision(staticEntityIndex, checkResult);
                    }
                }
            }
        }

        if(movingEntityCollisionCount == 0)
        {
            break;
        }
        game.logf("update %s: collision round %s has %s collisions to handle", updateID, collisionRound, movingEntityCollisionCount);

        size_t collisionsHandled = 0;
        foreach(movingEntityIndex; 0..movingEntities.dataLength)
        {
            auto movingEntity = movingEntities.getRef(movingEntityIndex);
            if(!movingEntity.collision.isSet)
            {
                continue;
            }
            scope(exit)
            {
            }

            game.logf("  collision: \"%s\" with \"%s\", %s",
                movingEntity.base.nameForLog,
                staticEntities.getRef(movingEntity.collision.staticEntityIndex).nameForLog,
                movingEntity.collision.check);

                /*
            game.logf("  velocityTotal %s, velocityLeft %s, noCollisionMove %s",
                movingEntity.oneStepVelocity,
                movingEntity.currentStepVelocityLeft,
                collision.check.noCollisionMove);
                */

            movingEntity.base.rectangle.move(movingEntity.collision.check.noCollisionMove);
            movingEntity.currentStepVelocityLeft -= movingEntity.collision.check.noCollisionMove;

            {
                bool xBlocked = false;
                bool yBlocked = false;

                // TODO: Change the velocity in the direction that caused the collision only
                final switch(movingEntity.collision.check.direction)
                {
                    case CollisionDirection.x:
                        xBlocked = true;
                        break;
                    case CollisionDirection.y:
                        yBlocked = true;
                        break;
                    case CollisionDirection.xAndY:
                        {
                            // TODO: I don't need to check the whole xShifted rectangle, I could just check a 1 pixel line
                            auto xShifted = movingEntity.base.rectangle.xShifted(movingEntity.currentStepVelocityLeft.x.normalizeToOne);
                            auto yShifted = movingEntity.base.rectangle.yShifted(movingEntity.currentStepVelocityLeft.y.normalizeToOne);

                            auto staticEntity = staticEntities.getRef(movingEntity.collision.staticEntityIndex);
                            if(xShifted.overlap(staticEntity.rectangle))
                            {
                                xBlocked = true;
                            }
                            if(yShifted.overlap(staticEntity.rectangle))
                            {
                                yBlocked = true;
                            }
                            if(!xBlocked && !yBlocked)
                            {
                                // TODO: collided perfectly on the corder
                                game.logf("CORNERCASE!!!!!!!!!!!!!!!!!");
                                if(movingEntity.oneStepVelocity.x > movingEntity.oneStepVelocity.y)
                                {
                                    yBlocked = true;
                                }
                                else if(movingEntity.oneStepVelocity.x < movingEntity.oneStepVelocity.y)
                                {
                                    xBlocked = true;
                                }
                                else
                                {
                                    // TODO: create a test for this, and reproduce/resolve it
                                    assert(0, "perfect corner collision not implemented");
                                }
                            }
                        }
                        break;
                }

                if(xBlocked)
                {
                    movingEntity.oneStepVelocity.x         = Unit(0);
                    movingEntity.currentStepVelocityLeft.x = Unit(0);
                }
                if(yBlocked)
                {
                    movingEntity.oneStepVelocity.y         = Unit(0);
                    movingEntity.currentStepVelocityLeft.y = Unit(0);
                }
            }

            movingEntity.collision.unset();
            collisionsHandled++;
            if(collisionsHandled >= movingEntityCollisionCount)
            {
                break;
            }
        }
    }
}
unittest
{
    static struct Collision
    {
        static auto none() { return Collision(size_t.max); }
        size_t staticEntityIndex;
        CollisionCheckResult check;
        @property bool isSet() { return staticEntityIndex != size_t.max; }
        void unset() { staticEntityIndex = size_t.max; }
        void toString(scope void delegate(const(char)[]) sink) const
        {
            formattedWrite(sink, "Collision with %s %s", staticEntityIndex, check);
        }
    }
    static struct Entity
    {
        UnitRectangle rectangle;
        string nameForLog;
        this(string nameForLog, UnitRectangle rectangle)
        {
            this.rectangle = rectangle;
            this.nameForLog = nameForLog;
        }
    }
    static struct MovingEntity
    {
        Entity base;
        //MassNoInfinite mass;
        auto ref rectangle() inout { return base.rectangle; }

        // TODO: implement max velocity from gravity!
        UnitVector oneStepVelocity; // units per time step
        UnitVector acceleration; // units per time step squared

        UnitVector currentStepVelocityLeft;
        Collision collision = Collision.none;

        void applyAccelerationAndResetCurrentStepVelocityLeft()
        {
            oneStepVelocity += acceleration;
            currentStepVelocityLeft = oneStepVelocity;
        }
    }
    {
        auto movingEntities = [
            MovingEntity(Entity("first" , pointSize(0, 0, 10, 10))),
            MovingEntity(Entity("second", pointSize(20, 0, 10, 10))),
        ];
        handleCollisions!(No.supportExistingOverlap)(movingEntities, movingEntities);
    }
}