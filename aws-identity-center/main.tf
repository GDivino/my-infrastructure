locals {
  default_tags = {
    ManagedBy = "terraform"
    TFProject = join("//", [
      "github.com/gdivino/my-infrastructure",
      "identity-center/",
    ])
  }
}

# fetch SSO admin instance
data "aws_ssoadmin_instances" "init" {}

resource "aws_identitystore_user" "jing" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.init.identity_store_ids)[0]

  display_name = "Gio Divino"
  user_name    = "jing"

  name {
    given_name  = "Gio"
    family_name = "Divino"
  }

  emails {
    value   = "giodivino.tech@gmail.com"
    primary = true
  }
}

resource "aws_identitystore_group" "admin" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.init.identity_store_ids)[0]
  display_name      = "admin"
}

resource "aws_identitystore_group_membership" "admin" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.init.identity_store_ids)[0]
  group_id          = aws_identitystore_group.admin.group_id
  member_id         = aws_identitystore_user.jing.user_id
}

resource "aws_ssoadmin_permission_set" "admin" {
  name         = "admin"
  instance_arn = tolist(data.aws_ssoadmin_instances.init.arns)[0]

  tags = local.default_tags
}

resource "aws_ssoadmin_managed_policy_attachment" "admin" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.init.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  depends_on = [aws_ssoadmin_permission_set.admin]
}

resource "aws_ssoadmin_account_assignment" "admin" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.init.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_id   = aws_identitystore_group.admin.group_id
  principal_type = "GROUP"

  target_id   = "926438432130"
  target_type = "AWS_ACCOUNT"

  depends_on = [aws_ssoadmin_permission_set.admin]
}
