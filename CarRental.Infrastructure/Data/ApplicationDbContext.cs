using CarRental.Domain.Models;
using Microsoft.EntityFrameworkCore;

namespace CarRental.Infrastructure.Data;

public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : DbContext(options)
{
    public DbSet<Car> Cars => Set<Car>();
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Rental> Rentals => Set<Rental>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Car>(entity =>
        {
            entity.HasKey(c => c.Id);
            entity.Property(c => c.Model).IsRequired().HasMaxLength(100);
            entity.Property(c => c.Brand).IsRequired().HasMaxLength(50);
            entity.Property(c => c.PricePerDay).HasColumnType("decimal(18,2)");
            entity.Property(c => c.Status).HasMaxLength(20).HasDefaultValue("Available");
        });

        modelBuilder.Entity<Customer>(entity =>
        {
            entity.HasKey(c => c.Id);
            entity.Property(c => c.Name).IsRequired().HasMaxLength(100);
            entity.Property(c => c.Email).IsRequired().HasMaxLength(150);
            entity.HasIndex(c => c.Email).IsUnique();
            entity.Property(c => c.Phone).HasMaxLength(20);
        });

        modelBuilder.Entity<Rental>(entity =>
        {
            entity.HasKey(r => r.Id);
            entity.Property(r => r.TotalPrice).HasColumnType("decimal(18,2)");
            entity.Property(r => r.Status).HasMaxLength(20).HasDefaultValue("Active");

            entity.HasOne(r => r.Car)
                  .WithMany(c => c.Rentals)
                  .HasForeignKey(r => r.CarId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.Customer)
                  .WithMany(c => c.Rentals)
                  .HasForeignKey(r => r.CustomerId)
                  .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
