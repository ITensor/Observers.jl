using Observers
using Test

@testset "Deprecated" begin
  # Check deprecation
  @test_throws ErrorException results(observer("Error" => Returns(0.0)))
  @test_throws ErrorException results(observer("Error" => Returns(0.0)), "Error")
  @test Observer("x" => sin, "y" => cos) == observer("x" => sin, "y" => cos)
end
