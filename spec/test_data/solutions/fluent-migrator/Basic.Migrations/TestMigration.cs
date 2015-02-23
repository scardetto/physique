using FluentMigrator;

namespace Basic.Migrations
{
    [Migration(1)]
    public class TestMigration : Migration
    {
        public override void Up()
        {
            Create.Table("TestTable")
                .WithColumn("Test").AsString();
        }

        public override void Down()
        {
            Delete.Table("TestTable");
        }
    }
}
