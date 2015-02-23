using NSpec;

namespace Basic.Tests
{
    public class describe_a_class : nspec
    {
        public void it_should_all_work_out()
        {
            1.should_be(1);
        }
    }
}
