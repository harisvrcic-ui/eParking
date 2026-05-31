using eParking.Model.Exceptions;
using eParking.Model;
using eParking.Services;
using eParking.Services.Database.Parking;

namespace eParking.Services.Tests;

public class ReservationStateMachineTests
{
    [Theory]
    [InlineData(ReservationStatus.Pending, ReservationStatus.Confirmed, true)]
    [InlineData(ReservationStatus.Pending, ReservationStatus.Cancelled, true)]
    [InlineData(ReservationStatus.Confirmed, ReservationStatus.Completed, true)]
    [InlineData(ReservationStatus.Confirmed, ReservationStatus.Cancelled, true)]
    [InlineData(ReservationStatus.Completed, ReservationStatus.Cancelled, false)]
    [InlineData(ReservationStatus.Cancelled, ReservationStatus.Confirmed, false)]
    public void CanTransition_matches_rs2_flow(
        ReservationStatus from,
        ReservationStatus to,
        bool expected)
    {
        Assert.Equal(expected, ReservationStateMachine.CanTransition(from, to));
    }

    [Fact]
    public void EnsureCanTransition_throws_on_invalid_transition()
    {
        Assert.Throws<BusinessException>(() =>
            ReservationStateMachine.EnsureCanTransition(
                ReservationStatus.Completed,
                ReservationStatus.Confirmed));
    }
}
