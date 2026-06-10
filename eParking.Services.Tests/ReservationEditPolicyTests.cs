using eParking.Model;
using eParking.Model.Exceptions;
using eParking.Services;

namespace eParking.Services.Tests;

public class ReservationEditPolicyTests
{
    [Theory]
    [InlineData(ReservationStatus.Pending, false, true)]
    [InlineData(ReservationStatus.Pending, true, true)]
    [InlineData(ReservationStatus.Confirmed, false, false)]
    [InlineData(ReservationStatus.Confirmed, true, true)]
    [InlineData(ReservationStatus.Cancelled, false, false)]
    [InlineData(ReservationStatus.Cancelled, true, false)]
    [InlineData(ReservationStatus.Completed, false, false)]
    [InlineData(ReservationStatus.Completed, true, false)]
    public void EnsureCanEdit_allows_only_expected_statuses(
        ReservationStatus status,
        bool isAdmin,
        bool shouldAllow)
    {
        if (shouldAllow)
            ReservationEditPolicy.EnsureCanEdit(status, isAdmin);
        else
            Assert.Throws<BusinessException>(() => ReservationEditPolicy.EnsureCanEdit(status, isAdmin));
    }

    [Theory]
    [InlineData(ReservationStatus.Confirmed, true, true)]
    [InlineData(ReservationStatus.Confirmed, false, false)]
    [InlineData(ReservationStatus.Pending, true, false)]
    [InlineData(ReservationStatus.Pending, false, false)]
    public void ShouldRevertConfirmedToPending_only_for_admin_confirmed(
        ReservationStatus status,
        bool isAdmin,
        bool expected)
    {
        Assert.Equal(expected, ReservationEditPolicy.ShouldRevertConfirmedToPending(status, isAdmin));
    }
}
